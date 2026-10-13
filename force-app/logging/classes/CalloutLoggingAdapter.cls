global with sharing class CalloutLoggingAdapter implements RequestLoggingInterface {
    private CalloutLogRedaction redaction;

    global CalloutLoggingAdapter() {
        this(new CalloutLogRedaction());
    }

    global CalloutLoggingAdapter(CalloutLogRedaction redaction) {
        this.redaction = redaction == null ? new CalloutLogRedaction() : redaction;
    }

    global void log(HttpRequest req, HttpResponse resp) {
        buildLog(req, resp).publish();
    }

    @testVisible
    private LogHelper buildLog(HttpRequest req, HttpResponse resp) {
        if (req == null) {
            throw new LogHelper.LogException('No HttpRequest available to log.');
        }
        if (resp == null) {
            throw new LogHelper.LogException('No HttpResponse available to log.');
        }

        return LogHelper.log(LogHelper.LOG_TYPE.API_CALLOUT)
            .withAPIEndpoint(redaction.redactUrlParameters(req.getEndpoint()))
            .withAPIMethod(req.getMethod())
            .withRequestHeaders('HttpRequest headers cannot be accessed in bulk')
            .withRequestBody(redaction.redactRequestBody(req))
            .withResponseHeaders(formatResponseHeaders(resp))
            .withResponseBody(redaction.redactResponseBody(resp))
            .withStatusCode(resp.getStatusCode());
    }

    private String formatResponseHeaders(HttpResponse response) {
        List<String> formatted = new List<String>();
        for (String headerName : response.getHeaderKeys()) {
            formatted.add(headerName + '=' + redaction.redactHeaderValue(headerName, response.getHeader(headerName)));
        }
        return String.join(formatted, '\r\n');
    }
}