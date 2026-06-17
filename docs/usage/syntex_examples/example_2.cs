using System;
using System.Collections.Generic;
using Newtonsoft.Json;
using Cysharp.Threading.Tasks;
using Ct = System.Threading.CancellationToken;

namespace Core.Apis
{
    public class name_controllerController //~rp name_controller
    {
        //# impl
        public static async UniTask<type_return> str_endpoint( //~rp type_return ; rp str_endpoint
            type_dto dto,                                      //~type_dto ! rp type_dto
            Ct ct = default) =>
            await new RequestBuilder()
                .AddQuery(dto)
                .SetMethod("str_method")                       //~rp str_method
                .SetEndpoint("str_endpoint")                   //~rp str_endpoint
                .AddAuthorization()
                .Send<type_return>(ct);                        //~rp type_return
        //#
    }
}
