# DTOS Context Template

A Template for DTOS Context Services

## Table of Contents

- [DTOS Context Template](#dtos-context-template)
  - [Table of Contents](#table-of-contents)
  - [Introduction](#introduction)
  - [Usage](#usage)
  - [Output](#output)


## Introduction

This repo contains the template for normalized context services, based upon the Clean Architecture paradigm.


## Usage

- Fork this repository to the desired location
- Modify Descriptions, Icons etc.. according to your needs
- UNFORK your target Repo
- git clone your repo locally
- execute:

```bash
$ ./init-repo.sh -u "$LOGATRON_USER>" -p "$LOGATRON_PASSWORD" -n "$API_PREFIX"
```

## Output

The following structure will be generated

```mono
--*-+
    |
    +-src----+- $API_PREFIX.Schema
    |        |- $API_PREFIX.Contract
    |        |- $API_PREFIX.Domain
    |        |- $API_PREFIX.Infra
    |        |- $API_PREFIX.Clients
    |        |- $API_PREFIX.Cmd
    |        |- $API_PREFIX.Qry
    |        |- $API_PREFIX.Etl
    |        +- $API_PREFIX.Sub
    |        
    |
    +-tests--+- $API_PREFIX.Schema.UnitTests
    |        |- $API_PREFIX.Contract.UnitTests
    |        |- $API_PREFIX.Domain.UnitTests
    |        |- $API_PREFIX.Infra.UnitTests
    |        |- $API_PREFIX.Clients.IntegrationTests
    |        +- $API_PREFIX.AcceptanceTests
    |        
    +-cid (submodule)
```