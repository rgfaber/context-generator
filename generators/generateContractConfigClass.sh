#! /bin/bash -x

# set -eu

generateContractConfigClass() {
  ## $1 API Prefix

  cat > Config.cs <<EOF
namespace $1.Contract
{
    public static class Config
    {

        public static class Errors
        {
            public const string ApiError = "$1.ApiError";
            public const string ServiceError = "$1.ApiError";
            public const string WebError = "$1.WebError";
        }


        public static class Hopes
        {
            public const string Initialize = "$1.Initialize";
        }

        public static class Facts
        {
            public const string Initialized = "$1.Initialized";            
        }


        public static class HopeEndpoints
        {
            public const string Initialize = "/api/initialize";
        }

        
        public static class QueryEndpoints
        {
            public const string First20 = "/api/first-20";
            public const string ById = "/api/by-id";
        }
        
    }
}  
EOF
}
