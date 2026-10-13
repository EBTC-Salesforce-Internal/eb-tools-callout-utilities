global class CalloutLogRedaction {
    private static final String REDACTED_VALUE = '[REDACTED]';
    private Set<String> headerNames = new Set<String>();
    private Set<String> urlParameterNames = new Set<String>();
    private List<Pattern> bodyPatterns = new List<Pattern>();

    global CalloutLogRedaction() {}

    global CalloutLogRedaction header(String name) {
        if (String.isBlank(name)) {
            throw new IllegalArgumentException('Header name cannot be blank.');
        }
        headerNames.add(name.toLowerCase());
        return this;
    }

    global CalloutLogRedaction urlParameter(String name) {
        if (String.isBlank(name)) {
            throw new IllegalArgumentException('URL parameter name cannot be blank.');
        }
        urlParameterNames.add(name.toLowerCase());
        return this;
    }

    global CalloutLogRedaction bodyPattern(String expression) {
        if (String.isBlank(expression)) {
            throw new IllegalArgumentException('Body pattern cannot be blank.');
        }
        bodyPatterns.add(Pattern.compile(expression));
        return this;
    }

    global String redactHeaderValue(String name, String value) {
        if (name != null && headerNames.contains(name.toLowerCase())) {
            return REDACTED_VALUE;
        }
        return value;
    }

    global String redactUrlParameters(String endpoint) {
        if (endpoint == null || urlParameterNames.isEmpty()) {
            return endpoint;
        }

        String fragment = '';
        Integer fragmentIndex = endpoint.indexOf('#');
        if (fragmentIndex >= 0) {
            fragment = endpoint.substring(fragmentIndex);
            endpoint = endpoint.substring(0, fragmentIndex);
        }

        Integer queryIndex = endpoint.indexOf('?');
        if (queryIndex < 0) {
            return endpoint + fragment;
        }

        String query = endpoint.substring(queryIndex + 1);
        String redactedEndpoint = endpoint.substring(0, queryIndex + 1);
        Integer segmentStart = 0;
        while (segmentStart < query.length()) {
            String remainingQuery = query.substring(segmentStart);
            Integer separatorOffset = remainingQuery.indexOf('&');
            Integer segmentEnd = separatorOffset < 0
                ? query.length()
                : segmentStart + separatorOffset;
            redactedEndpoint += redactUrlParameterSegment(query.substring(segmentStart, segmentEnd));

            if (separatorOffset < 0) {
                break;
            }
            redactedEndpoint += '&';
            segmentStart = segmentEnd + 1;
        }

        return redactedEndpoint + fragment;
    }

    global String redactBody(String value) {
        if (value == null) {
            return null;
        }

        String redacted = value;
        for (Pattern bodyPattern : bodyPatterns) {
            redacted = bodyPattern.matcher(redacted).replaceAll(REDACTED_VALUE);
        }
        return redacted;
    }

    global String redactRequestBody(HttpRequest request) {
        if (request == null) {
            return null;
        }
        String bodyText;
        try {
            bodyText = request.getBody();
        } catch (Exception ex) {
            return REDACTED_VALUE;
        }
        return redactBody(request.getBodyAsBlob(), bodyText);
    }

    global String redactResponseBody(HttpResponse response) {
        if (response == null) {
            return null;
        }
        String bodyText;
        try {
            bodyText = response.getBody();
        } catch (Exception ex) {
            return REDACTED_VALUE;
        }
        return redactBody(response.getBodyAsBlob(), bodyText);
    }

    private String redactBody(Blob body, String bodyText) {
        if (body == null) {
            return redactBody(bodyText);
        }
        if (bodyText == null) {
            return REDACTED_VALUE;
        }

        try {
            if (EncodingUtil.base64Encode(Blob.valueOf(bodyText)) == EncodingUtil.base64Encode(body)) {
                return redactBody(bodyText);
            }
        } catch (Exception ex) {
            return REDACTED_VALUE;
        }
        return REDACTED_VALUE;
    }

    private String redactUrlParameterSegment(String segment) {
        Integer valueSeparator = segment.indexOf('=');
        String encodedName = valueSeparator < 0 ? segment : segment.substring(0, valueSeparator);
        String parameterName = encodedName;
        try {
            parameterName = EncodingUtil.urlDecode(encodedName, 'UTF-8');
        } catch (Exception ex) {
            parameterName = encodedName;
        }

        if (!urlParameterNames.contains(parameterName.toLowerCase())) {
            return segment;
        }
        return encodedName + '=' + REDACTED_VALUE;
    }
}