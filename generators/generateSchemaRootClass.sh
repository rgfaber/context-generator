#! /bin/bash -x

# set -eu

generateSchemaRootClass() {
  cat> Root.cs <<EOF
using M5x.DEC.Schema;
using System;

namespace $1.Schema
{
    public interface IRoot: IStateEntity<Root.ID> {}
    
    [DbName(Attributes.DbName)]
    public record Root : IRoot
    {



        public static class Attributes
        {
            public const string IDPrefix = "$2";
            public const string DbName = "$3";
        }


        
        [Flags]
        public enum Flags
        {
            Unknown = 0,
            Pending = 1,
        }

        
        public Root() {}
        

        [IDPrefix(Attributes.IDPrefix)]
        public record ID: Identity<ID>
        {
            public ID(string value) : base(value)
            {
            }
        }

        public string Id { get; set; }
        public string Prev { get; set; }
        public AggregateInfo Meta { get; set; }
    }
}
EOF

}
