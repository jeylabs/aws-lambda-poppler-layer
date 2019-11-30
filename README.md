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

## Note

```
/var/lang/lib/libstdc++.so.6: version `CXXABI_1.3.9' not found
```

- Old version of GCC runtime users have to modify shared library search path by modifing `LD_LIBRARY_PATH` envirement variable without `/var/lang/lib` or `LD_LIBRARY_PATH=/opt/lib` is also fine.

## See
- `Node.js` - [aws-lambda-poppler](https://github.com/jeylabs/aws-lambda-poppler)