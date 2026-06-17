using System;
using System.Collections.Generic;
using Newtonsoft.Json;
using Cysharp.Threading.Tasks;
using Ct = System.Threading.CancellationToken;

namespace Core.Apis
{
    public class name_controllerController
    {
        //~
        public static async UniTask<type_return> GetQuestions( //~rp 'type_return'
            type_dto dto,                                      //~type_dto ? rp 'type_dto'
            Ct ct = default) =>
            await new RequestBuilder()
                .AddQuery(dto)
                .SetMethod("str_method")                       //~rp 'str_method'
                .SetEndpoint("str_endpoint")                   //~rp 'str_endpoint'
                .AddAuthorization()
                .Send<type_return>(ct);                        //~rp 'type_return'
        //~
    }
}
