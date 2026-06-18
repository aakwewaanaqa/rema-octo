# Examples

## Example 1

```oppl
file : regex ".*proj":dir . : {
    a |> b |> var aaa

    c |> ee |> ff:r:
      |> hi l k |> sub {
        yaaa |> var jkl
      }
}
```

1. `a:b` is enough but why `a : b` WTF
2. `a:b` ends but why `a:b:`
3. `c |> b` why on the same line

## Example 2

```oppl
a |> b |> c {
  a
  b
  c |> haha
} |> a
```

1. after a block has another pipe
