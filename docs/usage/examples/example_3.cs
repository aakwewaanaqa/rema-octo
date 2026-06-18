using System.Net;
using aimy_galaxy_proxy.Common;
using aimy_galaxy_proxy.DailyMission.Dto;
using aimy_galaxy_proxy.DailyMission.Service;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace aimy_galaxy_proxy.DailyMission.Controller;

[ApiController]
[Authorize(AuthenticationSchemes = "Token")]
[Route("api/daily-missions")]
public class DailyMissionController(IDailyMissionService _service) : ControllerBase
{
    private const int TaiwanTimezoneOffsetMinutes = 480;
    private CancellationToken _ct => HttpContext.RequestAborted;

    [HttpGet]
    [Route("today")]
    public async Task<ActionResult<Response<List<DailyQuestDto>>>> GetTodayMissions()
    {
        try
        {
            var result = await _service.GetTodayMissions(TaiwanTimezoneOffsetMinutes, _ct);
            return Ok(Response<List<DailyQuestDto>>.Ok(result));
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new Response<List<DailyQuestDto>>
            {
                status = (int)HttpStatusCode.BadRequest,
                errorCode = (int)ErrorCode.BadRequest,
                message = ex.Message
            });
        }
    }

    [HttpGet]
    [Route("today/status")]
    public async Task<ActionResult<Response<DailyMissionStatusDto>>> GetTodayMissionStatus()
    {
        var result = await _service.GetTodayMissionStatus(TaiwanTimezoneOffsetMinutes, _ct);
        return Ok(Response<DailyMissionStatusDto>.Ok(result));
    }

    [HttpGet]
    [Route("today/refresh")]
    public async Task<ActionResult<Response<DailyMissionStatusDto>>> RefreshTodayMissions()
    {
        try
        {
            var result = await _service.GetOrRefreshTodayMissionStatus(TaiwanTimezoneOffsetMinutes, _ct);
            return Ok(Response<DailyMissionStatusDto>.Ok(result));
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new Response<DailyMissionStatusDto>
            {
                status = (int)HttpStatusCode.BadRequest,
                errorCode = (int)ErrorCode.BadRequest,
                message = ex.Message
            });
        }
    }

    [HttpPost]
    [Route("today/complete")]
    public async Task<ActionResult<Response<DailyQuestProgressDto>>> CompleteTodayMission(
        [FromBody] CompleteDailyQuestDto dto)
    {
        if (dto == null)
        {
            return BadRequest(new Response<DailyQuestProgressDto>
            {
                status = (int)HttpStatusCode.BadRequest,
                errorCode = (int)ErrorCode.BadRequest,
                message = "Request body is required."
            });
        }

        var result = await _service.CompleteTodayMission(
            dto.DailyQuestType,
            TaiwanTimezoneOffsetMinutes,
            _ct);
        return Ok(Response<DailyQuestProgressDto>.Ok(result));
    }

    [HttpPost]
    [Route("today/progress")]
    public async Task<ActionResult<Response<DailyQuestProgressDto>>> UpdateTodayMissionProgress(
        [FromBody] UpdateDailyQuestProgressDto dto)
    {
        if (dto == null)
        {
            return BadRequest(new Response<DailyQuestProgressDto>
            {
                status = (int)HttpStatusCode.BadRequest,
                errorCode = (int)ErrorCode.BadRequest,
                message = "Request body is required."
            });
        }

        var result = await _service.UpdateTodayMissionProgress(
            dto.DailyQuestType,
            dto.Progress,
            TaiwanTimezoneOffsetMinutes,
            _ct);
        return Ok(Response<DailyQuestProgressDto>.Ok(result));
    }
}