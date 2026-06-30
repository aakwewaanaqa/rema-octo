const vscode = require('vscode')
const { exec } = require('child_process')
const path = require('path')
const os = require('os')
const { LanguageClient, TransportKind } = require('vscode-languageclient/node')

let client

// ── YAML hover hints ───────────────────────────────────────────────────────

const yamlKeyHints = {
    'escape': ['**`escape`**', 'Define an escape sequence definition.', '- `open` *(required)*: opening delimiter', '- `close`: closing delimiter (optional)', '- `crossLine`: span multiple lines'].join('\n\n'),
    'string': ['**`string`**', 'Define a string literal definition.', '- `open` *(required)*', '- `close` *(required)*', '- `escapedBy`: escape character', '- `crossLine`', '- `prefix`: allowed prefix chars'].join('\n\n'),
    'anchors': ['**`anchors`**', '1. Top-level — defines a named anchor with a regex pattern.', '2. Inside a finder — list of anchor names to scan for.'].join('\n\n'),
    'jobs': ['**`jobs`**', 'Define a job — a collection of finders.', '- `finders` *(required)*', '- `use.escapes` / `use.strings`', '- `fire`'].join('\n\n'),
    'fire': ['**`fire`**', 'Define a fire action.', '- `dir` *(required)*', '- `filename` *(required)*', '- `run.redirect` or `run.exe`'].join('\n\n'),
}

const completionInstructions = [
    { label: 'read', snippet: "read '${1:path}'", doc: 'Read a file, returns its content' },
    { label: 'write', snippet: "write '${1:path}'", doc: 'Write val to a file' },
    { label: 'find', snippet: "find '${1:regex}'", doc: 'Find files matching regex' },
    { label: 'ls', snippet: 'ls', doc: 'List current directory' },
    { label: 'cd', snippet: "cd '${1:path}'", doc: 'Change working directory' },
    { label: 'var', snippet: 'var ${1:name}', doc: 'Store val into ctx.vars' },
    { label: 'txt', snippet: "txt '${1:string}'", doc: 'Return a string literal' },
    { label: 'scope', snippet: "scope '${1:open}' '${2:close}'", doc: 'Extract text between delimiters' },
    { label: 'line', snippet: 'line ${1:0}', doc: 'Get nth line from val' },
    { label: 'magical', snippet: 'magical', doc: 'Run val as Magical template' },
    { label: 'macinterpret', snippet: 'macinterpret', doc: 'Alias for magical' },
    { label: 'exit', snippet: 'exit', doc: 'Stop execution' },
]

// ── Activate ───────────────────────────────────────────────────────────────

/** @param {vscode.ExtensionContext} context */
function activate(context) {
    const output = vscode.window.createOutputChannel('Octo')
    output.appendLine('Octo extension activated')

    // ── LSP client — hover handled server-side ─────────────────────────────
    const lspBin = path.join(__dirname, '..', 'bin', 'oppl-lsp')
    output.appendLine(`LSP bin: ${lspBin}`)
    output.appendLine(`ruby: /Users/ponito/.rbenv/shims/ruby`)
    try {
        client = new LanguageClient(
            'oppl-lsp',
            'Oppl LSP',
            { command: '/Users/ponito/.rbenv/shims/ruby', args: [lspBin] },
            { documentSelector: [{ scheme: 'file', language: 'octo-pipeline' }], outputChannel: output }
        )
        output.appendLine('LanguageClient created')
        client.start().then(() => output.appendLine('LSP started')).catch(e => output.appendLine(`LSP start error: ${e.message}`))
    } catch (e) {
        output.appendLine(`LSP init error: ${e.message}`)
    }

    // ── Completion for .oppl ───────────────────────────────────────────────
    const completionProvider = vscode.languages.registerCompletionItemProvider(
        'octo-pipeline',
        {
            provideCompletionItems() {
                return completionInstructions.map(i => {
                    const item = new vscode.CompletionItem(i.label, vscode.CompletionItemKind.Function)
                    item.insertText = new vscode.SnippetString(i.snippet)
                    item.documentation = new vscode.MarkdownString(i.doc)
                    return item
                })
            }
        }
    )

    // ── YAML hover ─────────────────────────────────────────────────────────
    const yamlHoverProvider = vscode.languages.registerHoverProvider(
        { language: 'yaml', pattern: '**/*.octo.yaml' },
        {
            provideHover(document, position) {
                const wordRange = document.getWordRangeAtPosition(position, /[a-zA-Z][a-zA-Z0-9]*/)
                if (!wordRange) return
                const word = document.getText(wordRange)
                if (yamlKeyHints[word]) {
                    return new vscode.Hover(new vscode.MarkdownString(yamlKeyHints[word]))
                }
            }
        }
    )

    // ── Commands + CodeLens ────────────────────────────────────────────────
    const runJobCommand = vscode.commands.registerCommand('octo.runJob', (jobName, configPath, noFire) => {
        const terminal = vscode.window.createTerminal(noFire ? `Octo preview: ${jobName}` : `Octo: ${jobName}`)
        terminal.show()
        terminal.sendText(`octo job "${jobName}" -c "${configPath}"${noFire ? ' --no-fire' : ''}`)
    })

    const runAnchorCommand = vscode.commands.registerCommand('octo.runAnchor', async (anchorName, configPath) => {
        const active = vscode.window.activeTextEditor?.document
        const activeFile = active && !active.fileName.endsWith('.octo.yaml') ? active.fileName : null
        const items = [
            ...(activeFile ? [{ label: path.basename(activeFile), description: activeFile, value: activeFile }] : []),
            { label: '$(folder-opened) Browse...', description: 'Pick a source file', value: '__browse__' }
        ]
        const picked = await vscode.window.showQuickPick(items, { title: `Scan anchor "${anchorName}"` })
        if (!picked) return
        let srcPath = picked.value
        if (srcPath === '__browse__') {
            const uris = await vscode.window.showOpenDialog({ canSelectMany: false, canSelectFolders: false })
            if (!uris || uris.length === 0) return
            srcPath = uris[0].fsPath
        }
        const terminal = vscode.window.createTerminal(`Octo anchor: ${anchorName}`)
        terminal.show()
        terminal.sendText(`octo anchor "${anchorName}" -c "${configPath}" -s "${srcPath}"`)
    })

    const octoLensProvider = vscode.languages.registerCodeLensProvider(
        { language: 'yaml', pattern: '**/*.octo.yaml' },
        {
            provideCodeLenses(document) {
                const lenses = []
                for (let i = 0; i < document.lineCount; i++) {
                    const text = document.lineAt(i).text
                    const jobMatch = text.match(/^jobs\s+(.+?)\s*:/)
                    if (jobMatch) {
                        const range = new vscode.Range(i, 0, i, text.length)
                        lenses.push(new vscode.CodeLens(range, { title: '▶ Run Job', command: 'octo.runJob', arguments: [jobMatch[1], document.fileName, false] }))
                        lenses.push(new vscode.CodeLens(range, { title: '👁 Preview', command: 'octo.runJob', arguments: [jobMatch[1], document.fileName, true] }))
                    }
                    const anchorMatch = text.match(/^anchors\s+(.+?)\s*:/)
                    if (anchorMatch) {
                        const range = new vscode.Range(i, 0, i, text.length)
                        lenses.push(new vscode.CodeLens(range, { title: '🔍 Scan Anchor', command: 'octo.runAnchor', arguments: [anchorMatch[1], document.fileName] }))
                    }
                }
                return lenses
            }
        }
    )

    // ── Diagnostics (.octo.yaml) ───────────────────────────────────────────
    const diagnosticCollection = vscode.languages.createDiagnosticCollection('octo')
    const octoExe = () => vscode.workspace.getConfiguration('octo').get('executablePath', 'octo')

    const runCheck = (doc) => {
        if (!doc.fileName.endsWith('.octo.yaml')) return
        const exe = octoExe()
        const zshrc = path.join(os.homedir(), '.zshrc')
        const cmd = `zsh -c 'source ${zshrc} 2>/dev/null; "${exe}" check -c "${doc.fileName}" --json'`
        exec(cmd, (err, stdout) => {
            if (err && !stdout) { output.appendLine(`ERROR: ${err.message}`); return }
            try {
                const issues = JSON.parse(stdout || '[]')
                diagnosticCollection.set(doc.uri, issues.map(i => new vscode.Diagnostic(
                    new vscode.Range(Math.max(0, (i.line || 1) - 1), 0, Math.max(0, (i.line || 1) - 1), 999),
                    `[${i.location}] ${i.message}`,
                    i.severity === 'error' ? vscode.DiagnosticSeverity.Error : vscode.DiagnosticSeverity.Warning
                )))
            } catch (e) { output.appendLine(`Parse error: ${e.message}`) }
        })
    }

    context.subscriptions.push(
        output,
        diagnosticCollection,
        completionProvider,
        yamlHoverProvider,
        runJobCommand,
        runAnchorCommand,
        octoLensProvider,
        vscode.workspace.onDidSaveTextDocument(runCheck),
        vscode.workspace.onDidOpenTextDocument(runCheck)
    )
}

function deactivate() {
    return client?.stop()
}

module.exports = { activate, deactivate }
