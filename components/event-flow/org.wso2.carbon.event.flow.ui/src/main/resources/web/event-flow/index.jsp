<%--
  ~ Copyright (c) 2015, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
  ~
  ~ Licensed under the Apache License, Version 2.0 (the "License");
  ~ you may not use this file except in compliance with the License.
  ~ You may obtain a copy of the License at
  ~
  ~     http://www.apache.org/licenses/LICENSE-2.0
  ~
  ~ Unless required by applicable law or agreed to in writing, software
  ~ distributed under the License is distributed on an "AS IS" BASIS,
  ~ WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  ~ See the License for the specific language governing permissions and
  ~ limitations under the License.
  --%>

<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ page import="org.apache.axis2.context.ConfigurationContext" %>
<%@ page import="org.wso2.carbon.CarbonConstants" %>
<%@ page import="org.wso2.carbon.event.flow.ui.client.EventFlowAdminServiceClient" %>
<%@ page import="org.wso2.carbon.ui.CarbonUIUtil" %>
<%@ page import="org.wso2.carbon.utils.ServerConstants" %>
<%@ taglib uri="http://wso2.org/projects/carbon/taglibs/carbontags.jar" prefix="carbon" %>
<fmt:bundle basename="org.wso2.carbon.event.flow.ui.i18n.Resources">
    <carbon:breadcrumb
            label="eventflowmenutext"
            resourceBundle="org.wso2.carbon.event.flow.ui.i18n.Resources"
            topPage="true"
            request="<%=request%>"/>
    <script src="../carbon/global-params.js" type="text/javascript"></script>
    <script type="text/javascript" src="js/d3.v3.min.js"></script>
    <script type="text/javascript" src="js/dagre-d3.min.js"></script>
    <script type="text/javascript" src="js/graphlib-dot.min.js"></script>
    <link rel="stylesheet" href="css/eventflow.css"/>

    <%
        String backendServerURL = CarbonUIUtil.getServerURL(config.getServletContext(), session);
        ConfigurationContext configContext =
                (ConfigurationContext) config.getServletContext()
                        .getAttribute(CarbonConstants.CONFIGURATION_CONTEXT);

        String cookie = (String) session.getAttribute(ServerConstants.ADMIN_SERVICE_COOKIE);
        EventFlowAdminServiceClient client;
        String[] logs = new String[0];
        try {
            client = new EventFlowAdminServiceClient(cookie, backendServerURL, configContext,
                    request.getLocale());


            String eventFlow = client.getEventFlow();

    %>
    <script type="text/javascript">
        var eventFlow = jQuery.parseJSON(<%=eventFlow%>);
    </script>
    <%
    } catch (Exception e) {
    %>
    <script type="text/javascript">
        window.location.href = "../admin/error.jsp";
    </script>
    <%
        }
    %>

    <script type="text/javascript">


        wso2.wsf.Util.initURLs();

        var frondendURL = wso2.wsf.Util.getServerURL() + "/";

        window.onload = function () {
            tryDrawProcessingFlowInfo();
            tryDraw();
            removeMargins();
        };

        function tryDrawProcessingFlowInfo() {

            var g = new dagreD3.Digraph();

            g.addNode("EventReceivers", {label: '<div onclick="location.href = \'../eventreceiver/index.jsp \';" onmouseover="" style="cursor: pointer;"><span class="infoType type type-ER  type-ER-info"></span><span name="nameElement" style="margin-right: 25px;" class="name-info" ><fmt:message key="event.receivers"/></span></div>'});
            g.addNode("EventStreams", {label: '<div onclick="location.href = \'../eventstream/index.jsp \';" onmouseover="" style="cursor: pointer;"><span class="infoType type type-ES  type-ES-info"></span><span name="nameElement" style="margin-right: 25px;" class="name-info" ><fmt:message key="event.streams"/></span></div>'});
            g.addNode("ExecutionPlans", {label: '<div onclick="location.href = \'../eventprocessor/index.jsp \';" onmouseover="" style="cursor: pointer;"><span class="infoType type type-EXP type-EXP-info"></span><span name="nameElement" style="margin-right: 25px;" class="name-info" ><fmt:message key="execution.plans"/></span></div>'});
            g.addNode("EventPublishers", {label: '<div onclick="location.href = \'../eventpublisher/index.jsp \';" onmouseover="" style="cursor: pointer;"><span class="infoType type type-EP  type-EP-info"></span><span name="nameElement" style="margin-right: 25px;" class="name-info" ><fmt:message key="event.publishers"/></span></div>'});

            var renderer = new dagreD3.Renderer();

            var svg = d3.select("#flowInfo");
            var svgGroup = d3.select("#flowInfo g");

            renderer.zoom(false);

            var layout = dagreD3.layout()
                    .nodeSep(30)
                    .edgeSep(30)
                    .rankSep(40);
//            .rankDir("LR");
            renderer.layout(layout);

            layout = renderer.run(g, svgGroup);

            svg.attr("width", layout.graph().width).attr("height", layout.graph().height);

        }

        function tryDraw() {

            var nodes = eventFlow.nodes;

            if (nodes.length == 0) {

                var noDataDiv = document.getElementById('noDataDiv');
                noDataDiv.style.display = "block";
                var flowDiv = document.getElementById('flowdiv');
                flowDiv.style.display = "none";

            } else {

                var g = new dagreD3.Digraph();

                for (var i = 0; i < nodes.length; i++) {
                    g.addNode(nodes[i].id, {label: '<div onclick="location.href = \'' + nodes[i].url + ' \';" onmouseover="" style="cursor: pointer;" ><span class="type type-' + nodes[i].nodeclass + '"></span><span name="nameElement" class="name" style="margin-right: 10px;">' + nodes[i].label + '</span></div>'});
                }

                var edges = eventFlow.edges;
                for (i = 0; i < edges.length; i++) {
                    g.addEdge(null, edges[i].from, edges[i].to);
                }

                var renderer = new dagreD3.Renderer();

                var svg = d3.select("#flowData");
                var svgGroup = d3.select("#flowData g");

                // Set initial zoom to 75%
                var initialScale = 0.75;
                var oldZoom = renderer.zoom();
                renderer.zoom(function (graph, svg) {
                    var zoom = oldZoom(graph, svg);

                    // We must set the zoom and then trigger the zoom event to synchronize
                    // D3 and the DOM.
                    zoom.scale(initialScale).event(svg);
                    return zoom;
                });

                var layout = dagreD3.layout()
                        .nodeSep(10)
                        .edgeSep(10)
                        .rankDir("LR");
                renderer.layout(layout);

                layout = renderer.run(g, svgGroup);

                svg.transition().duration(500)
                        .attr("width", layout.graph().width * initialScale + 40)
                        .attr("height", layout.graph().height * initialScale + 40);
            }

        }

        function removeMargins() {

            var nameElements = document.getElementsByName("nameElement");
            for (var i = 0; i < nameElements.length; i++) {
                nameElements[i].style.cssText = "margin-right: 0px; ";
            }

        }

    </script>

    <div id="middle">
        <h2><fmt:message key="event.flow"/></h2>

        <div id="workArea">
            <div id="flowdivInfo">
                <svg id="flowInfo" width=100% height=100%>
                    <g transform="translate(0,0)scale(0.75)"></g>
                </svg>

            </div>
            <h2 style="border-bottom:solid 1px #d2d2d2"></h2>

            <div id="flowdiv">
                <svg id="flowData" width=100% height=100% style="border: 1px solid #d2d2d2;">
                    <g transform="translate(20, 20)"></g>
                </svg>
            </div>
            <div id="noDataDiv" style="display: none">
                <table class="styledLeft">
                    <tbody>
                    <tr>
                        <td class="formRaw">
                            <table id="noExecutionPlanInputTable" class="normal-nopadding" style="width:100%">
                                <tbody>

                                <tr>
                                    <td class="leftCol-med" colspan="2">No deployment elements to be listed
                                    </td>
                                </tr>
                                </tbody>
                            </table>
                        </td>
                    </tr>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</fmt:bundle>
