/*
 * Copyright (c) 2016, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.wso2.carbon.event.processor.template.deployer;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.wso2.carbon.event.processor.core.exception.ExecutionPlanConfigurationException;
import org.wso2.carbon.event.processor.core.exception.ExecutionPlanDependencyValidationException;
import org.wso2.carbon.event.processor.core.internal.util.EventProcessorConstants;
import org.wso2.carbon.event.processor.template.deployer.internal.ExecutionPlanDeployerConstants;
import org.wso2.carbon.event.processor.template.deployer.internal.ExecutionPlanDeployerValueHolder;
import org.wso2.carbon.event.template.manager.core.DeployableTemplate;
import org.wso2.carbon.event.template.manager.core.TemplateDeployer;
import org.wso2.carbon.event.template.manager.core.TemplateDeploymentException;
import org.wso2.siddhi.query.api.util.AnnotationHelper;
import org.wso2.siddhi.query.compiler.SiddhiCompiler;
import org.wso2.siddhi.query.compiler.exception.SiddhiParserException;

public class ExecutionPlanTemplateDeployer implements TemplateDeployer {

    private static final Log log = LogFactory.getLog(ExecutionPlanTemplateDeployer.class);

    @Override
    public String getType() {
        return "realtime";
    }

    @Override
    public void deployArtifact(DeployableTemplate template) throws TemplateDeploymentException {
        String planName;
        try {
            if (template == null) {
                throw new TemplateDeploymentException("No artifact received to be deployed.");
            }
            planName = template.getArtifactId();
            planName = planName.replaceAll(" ", "_");
            undeployArtifact(planName);

            // configuring plan name etc
            String updatedExecutionPlan = template.getArtifact();
            String executionPlanNameDefinition = ExecutionPlanDeployerConstants.EXECUTION_PLAN_NAME_ANNOTATION + "('"
                    + planName + "')";

            if (AnnotationHelper.getAnnotationElement(
                    EventProcessorConstants.ANNOTATION_NAME_NAME, null,
                    SiddhiCompiler.parse(updatedExecutionPlan).getAnnotations()) == null
                    || !updatedExecutionPlan.contains(ExecutionPlanDeployerConstants.EXECUTION_PLAN_NAME_ANNOTATION)) {
                updatedExecutionPlan = executionPlanNameDefinition + updatedExecutionPlan;
            } else {
                //@Plan:name will be updated with given configuration name and uncomment in case if it is commented
                updatedExecutionPlan = updatedExecutionPlan.replaceAll(
                        ExecutionPlanDeployerConstants.EXECUTION_PLAN_NAME_ANNOTATION
                                + ExecutionPlanDeployerConstants.REGEX_NAME_COMMENTED_VALUE,
                        executionPlanNameDefinition);
            }

            //Get Template Execution plan, Tenant Id and deploy Execution Plan
            ExecutionPlanDeployerValueHolder.getEventProcessorService()
                    .deployExecutionPlan(updatedExecutionPlan);

        } catch (SiddhiParserException e) {
            throw new TemplateDeploymentException(
                    "Validation exception occurred when parsing Execution Plan of Template "
                            + template.getConfiguration().getName() + " of Domain " + template.getConfiguration().getDomain(), e);
        } catch (ExecutionPlanConfigurationException e) {
            throw new TemplateDeploymentException(
                    "Configuration exception occurred when adding Execution Plan of Template "
                    + template.getConfiguration().getName() + " of Domain " + template.getConfiguration().getDomain(), e);

        } catch (ExecutionPlanDependencyValidationException e) {
            throw new TemplateDeploymentException(
                    "Validation exception occurred when adding Execution Plan of Template "
                    + template.getConfiguration().getName() + " of Domain " + template.getConfiguration().getDomain(), e);
        }
    }

    @Override
    public void deployIfNotDoneAlready(DeployableTemplate template) throws TemplateDeploymentException{
        if (template == null) {
            throw new TemplateDeploymentException("No artifact received to be deployed.");
        }
        String planName = template.getArtifactId();
        planName = planName.replaceAll(" ", "_");
        if (ExecutionPlanDeployerValueHolder.getEventProcessorService().
                getAllActiveExecutionConfigurations().get(planName) == null) {
            deployArtifact(template);
        } else {
            if(log.isDebugEnabled()) {
                log.debug("Common Artifact: " + planName + " of Domain " + template.getConfiguration().getDomain()
                          + " was not deployed as it is already being deployed.");
            }
        }
    }

    @Override
    public void undeployArtifact(String artifactId) throws TemplateDeploymentException {
        artifactId = artifactId.replaceAll(" ", "_");
        try {
            if (ExecutionPlanDeployerValueHolder.getEventProcessorService().getAllActiveExecutionConfigurations().keySet().contains(artifactId)) {
                ExecutionPlanDeployerValueHolder.getEventProcessorService().undeployActiveExecutionPlan(artifactId);
            } else {
                ExecutionPlanDeployerValueHolder.getEventProcessorService().undeployInactiveExecutionPlan(artifactId + EventProcessorConstants.EP_CONFIG_FILE_EXTENSION_WITH_DOT);
            }
        } catch (ExecutionPlanConfigurationException e) {
            throw new TemplateDeploymentException("Could not undeploy exceution plan: " + artifactId, e);
        }
    }
}
