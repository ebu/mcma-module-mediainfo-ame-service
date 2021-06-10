import * as util from "util";
import * as childProcess from "child_process";

import { AmeJob, McmaException } from "@mcma/core";
import { ProcessJobAssignmentHelper, ProviderCollection } from "@mcma/worker";
import { AwsS3FileLocator, AwsS3FileLocatorProperties } from "@mcma/aws-s3";
import { S3 } from "aws-sdk";

const { OutputBucket } = process.env;

const execFile = util.promisify(childProcess.execFile);

export async function mediaInfo(params: string[]) {
    try {
        const { stdout, stderr } = await execFile("/opt/bin/mediainfo", params);
        return { stdout, stderr };
    } catch (error) {
        throw new McmaException("Failed to run media info", error);
    }
}

export async function extractTechnicalMetadata(providers: ProviderCollection, jobAssignmentHelper: ProcessJobAssignmentHelper<AmeJob>, ctx: { s3: S3 }) {
    const logger = jobAssignmentHelper.logger;
    const jobInput = jobAssignmentHelper.jobInput;

    logger.info("Execute media info on input file");
    let inputFile = jobInput.get<AwsS3FileLocatorProperties>("inputFile");

    let output;

    if (inputFile.url) {
        logger.info("Obtaining mediainfo output based on url " + inputFile.url);
        output = await mediaInfo(["--Output=EBUCore_JSON", inputFile.url]);
    } else {
        throw new McmaException("Not able to obtain input file");
    }

    logger.info("Check if we have mediaInfo output:");
    logger.info(logger);
    if (!output?.stdout) {
        throw new McmaException("Failed to obtain mediaInfo stdout");
    }

    let filename = inputFile.url;
    let pos = filename.lastIndexOf("/");
    if (pos >= 0) {
        filename = filename.substring(pos + 1);
    }
    pos = filename.indexOf("?");
    if (pos >= 0) {
        filename = filename.substring(0, pos);
    }
    pos = filename.lastIndexOf(".");
    if (pos >= 0) {
        filename = filename.substring(0, pos);
    }

    const objectKey = `mediainfo-ame-service/${new Date().toISOString().substring(0, 19).replace(/[:]/g, "-")}/${filename}.json`;

    const outputFile = await putFile(objectKey, output?.stdout, ctx.s3);

    jobAssignmentHelper.jobOutput.set("outputFile", outputFile);

    logger.info("Marking JobAssignment as completed");
    await jobAssignmentHelper.complete();
}

async function putFile(objectKey: string, body: string, s3: S3) {
    const params: S3.PutObjectRequest = {
        Bucket: OutputBucket,
        Key: objectKey,
        Body: body
    };

    await s3.putObject(params).promise();

    return new AwsS3FileLocator({
        bucket: params.Bucket,
        key: params.Key,
        url: s3.getSignedUrl("getObject", {
            Bucket: params.Bucket,
            Key: params.Key,
            Expires: 7 * 24 * 3600
        })
    });
}
