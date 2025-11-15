package com.nn_challenge.nn_devops_challenge;

import com.nn_challenge.nn_devops_challenge.model.StatusResponse;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class StatusController {

    // In your real version, call AWS SDK (EKS DescribeCluster, etc.)
    @GetMapping("/status/eks")
    public StatusResponse eksStatus() {
        return new StatusResponse(
                "HEALTHY",
                "EKS cluster API reachable (mocked)."
        );
    }

    // In your real version: call Azure DevOps REST API to get latest pipeline result
    @GetMapping("/status/pipeline")
    public StatusResponse pipelineStatus() {
        return new StatusResponse(
                "SUCCEEDED",
                "Latest pipeline run succeeded (mocked)."
        );
    }
}