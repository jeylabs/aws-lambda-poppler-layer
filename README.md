# This is required for Depot-serverless

When the package is built, ensure that the zip file is uploaded to `s3://aspire-operations/binaries/poppler.zip` This is required for the serverless image to build.

## Build Poppler for Amazon Lambda as a layer

Poppler binaries for AWS Lambda

![Release](https://github.com/talis/aws-lambda-poppler-layer/workflows/Release/badge.svg)

## Getting Started

Download `poppler.zip` file from [releases](https://github.com/talis/aws-lambda-poppler-layer/releases) and create / update your custom layer in AWS. You can add this layer to any Lambda function you want – no matter what runtime.

## Fonts

[Stix](https://github.com/stipub/stixfonts/tree/master/OTF) fonts added as fallback fonts. you can place your custom fonts in `/tmp/fonts` directory in runtime.

## Install

Clone this repository and run `make distribution`
