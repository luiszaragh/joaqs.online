// CloudFront viewer-request function. Two jobs, both of which have to happen
// before the request reaches S3.
//
//  1. Redirect www to the apex, so there is one canonical hostname. Two
//     hostnames serving identical content split the access logs and weaken the
//     Athena analysis in DECISIONS.md #22.
//
//  2. Rewrite directory-style URIs to the index.html underneath them. This is
//     not cosmetic: the origin is the S3 REST endpoint (required by OAC), not
//     the S3 website endpoint, and the REST endpoint has no concept of a
//     directory index. Without this rewrite every page except "/" returns 403.
//
// Written for the cloudfront-js-2.0 runtime. Kept to conservative syntax —
// this runs on every single request and is not worth being clever in.

function buildQueryString(qs) {
    var parts = [];

    for (var key in qs) {
        if (!Object.prototype.hasOwnProperty.call(qs, key)) {
            continue;
        }

        var param = qs[key];

        if (param.multiValue) {
            for (var i = 0; i < param.multiValue.length; i++) {
                parts.push(encodeURIComponent(key) + '=' + encodeURIComponent(param.multiValue[i].value));
            }
        } else if (param.value === '') {
            parts.push(encodeURIComponent(key));
        } else {
            parts.push(encodeURIComponent(key) + '=' + encodeURIComponent(param.value));
        }
    }

    return parts.length > 0 ? '?' + parts.join('&') : '';
}

function handler(event) {
    var request = event.request;
    var host = request.headers.host ? request.headers.host.value : '';
    var uri = request.uri;

    if (host.substring(0, 4) === 'www.') {
        var apex = host.substring(4);
        var query = buildQueryString(request.querystring);

        return {
            statusCode: 301,
            statusDescription: 'Moved Permanently',
            headers: {
                'location': { value: 'https://' + apex + uri + query },
                'cache-control': { value: 'max-age=3600' }
            }
        };
    }

    var lastSegment = uri.substring(uri.lastIndexOf('/') + 1);

    if (uri.charAt(uri.length - 1) === '/') {
        // "/blog/" -> "/blog/index.html"
        request.uri = uri + 'index.html';
    } else if (lastSegment.indexOf('.') === -1) {
        // "/blog" -> "/blog/index.html". Only extensionless paths, so a request
        // for "/favicon.svg" or "/_astro/index.abc123.css" passes through
        // untouched.
        request.uri = uri + '/index.html';
    }

    return request;
}
