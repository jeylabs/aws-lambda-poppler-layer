## Build Poppler for Amazon Lambda as a layer
Poppler binaries for AWS Lambda

## Install
Download and run `make distribution`

## Getting Started
You can add this layer to any Lambda function you want – no matter what runtime

Click on Layers and choose "Add a layer", and "Provide a layer version ARN" and enter the following ARN.

```
arn:aws:lambda:ap-southeast-2:544607081959:layer:poppler:9
```

See the table below for other supported regions.
Works well with [aws-lambda-poppler](https://github.com/jeylabs/aws-lambda-poppler) npm package
