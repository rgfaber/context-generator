#! /bin/bash -x

# set -eu
generateSchemaConstants() {
    cat >Constants.cs<<EOF
namespace $1.Schema
{
    public static class Constants
    {

        public static class Hopes
        {
            public const string Initialize = "$1.Initialize";
        }

        public static class Facts
        {
            public const string Initialized = "$1.Initialized";
        }



        public static class Errors
        {
            public const string ServiceError = "$1.ServiceError";
            public const string DomainError = "$1.DomainError";
            public const string WebError = "$1.WebError";
            public const string ApiError = "$1.ApiError";            
            public const string Exception = "$1.Exception";
        }


        public static class Statuses
        {
            public const string Unknown = "$1.Unknown";
            public const string Initialized = "$1.Initialized";
        }
    }
}
EOF
}

