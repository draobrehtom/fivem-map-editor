function getEntityClassName(c) {
    if (c == 1) { return 'spawnpoint'; }
    else if (c == 2) { return 'object'; }
    else if (c == 3) { return 'vehicle'; }
    return 'undefined';
}

function isEmpty(value) {
    return typeof value == 'string' && !value.trim() || typeof value == 'undefined' || value === null;
}

function stringToHash(string) {
    var hash = 0;
    if (string.length == 0) { return hash; }

    for (i = 0; i < string.length; i++) {
        char = string.charCodeAt(i);
        hash = ((hash << 5) - hash) + char;
        hash = hash & hash;
    }

    return hash;
}