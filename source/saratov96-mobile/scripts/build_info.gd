extends RefCounted
class_name S96BuildInfo

const BUILD_VERSION: String = "mobile-v1"
const BUILD_COMMIT: String = "dev"

static func short_commit() -> String:
    if BUILD_COMMIT.length() <= 8:
        return BUILD_COMMIT
    return BUILD_COMMIT.substr(0, 8)
