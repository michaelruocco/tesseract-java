# Java Tesseract

A base image for use with Java applications that use tesseract

## Building locally

To build the runtime image locally you can run:

```bash
docker build -target runtime -t tesseract-java-runtime .
```

To build the ci image locally you can run:

```bash
docker build -target ci -t tesseract-java-ci .
```