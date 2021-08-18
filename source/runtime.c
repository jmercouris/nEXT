#include "globals.h"
#include "extevent.h"
#include "runtime.h"

Runtime *RUNTIME;

static JSCValue *
runtime_send_message_result_callback ()
{
        JSCContext *context = jsc_context_get_current();
        return jsc_value_new_from_json(context, RUNTIME->reply);
}

static void
runtime_send_message_callback (char *extension_id, JSCValue *object)
{
        JSCContext *context = jsc_context_get_current();
        JSCValue *wrapper = jsc_value_new_object(context, NULL, NULL);
        jsc_value_object_set_property(
                wrapper, "extensionId",
                jsc_value_new_string(context, extension_id));
        jsc_value_object_set_property(wrapper, "message", object);
        char *json = jsc_value_to_json(wrapper, 0);
        GVariant *variant = g_variant_new("s", json);
        WebKitUserMessage *message = webkit_user_message_new("runtime.sendMessage", variant);
        RUNTIME->reply = "null";
        webkit_web_page_send_message_to_view(
                PAGE, message, NULL, message_reply_and_save_callback, &RUNTIME->reply);
}

static JSCValue *
runtime_get_manifest_callback (char *extension_name)
{
        ExtensionData *data = g_hash_table_lookup(EXTENSIONS_DATA, extension_name);
        JSCContext *context = jsc_context_get_current();
        return jsc_value_new_from_json(context, jsc_value_to_json(data->manifest, 0));
}

static JSCValue *
runtime_get_platform_info_result_callback ()
{
        JSCContext *context = jsc_context_get_current();
        return jsc_value_new_from_json(context, RUNTIME->platform_info);
}

static void
runtime_get_platform_info_callback ()
{
        WebKitUserMessage *message = webkit_user_message_new("runtime.getPlatformInfo", NULL);
        RUNTIME->platform_info = "{}";
        webkit_web_page_send_message_to_view(
                PAGE, message, NULL, message_reply_and_save_callback, &RUNTIME->platform_info);
}

static JSCValue *
runtime_get_browser_info_result_callback ()
{
        JSCContext *context = jsc_context_get_current();
        return jsc_value_new_from_json(context, RUNTIME->browser_info);
}

static void
runtime_get_browser_info_callback ()
{
        WebKitUserMessage *message = webkit_user_message_new("runtime.getBrowserInfo", NULL);
        RUNTIME->browser_info = "{}";
        webkit_web_page_send_message_to_view(
                PAGE, message, NULL, message_reply_and_save_callback, &RUNTIME->browser_info);
}

void inject_runtime_api (char* extension_name)
{
        JSCContext *context = get_extension_context(extension_name);
        MAKE_CLASS(context, Runtime, "runtime");

        MAKE_FN(context, runtimeSendMessage, runtime_send_message_callback, G_TYPE_NONE, 2, G_TYPE_STRING, JSC_TYPE_VALUE);
        MAKE_FN(context, runtimeSendMessageResult, runtime_send_message_result_callback, JSC_TYPE_VALUE, 0, G_TYPE_NONE);
        MAKE_FN(context, runtimeGetManifest, runtime_get_manifest_callback, JSC_TYPE_VALUE, 1, G_TYPE_STRING);
        MAKE_FN(context, runtimeGetPlatformInfo, runtime_get_platform_info_callback, G_TYPE_NONE, 0, G_TYPE_NONE);
        MAKE_FN(context, runtimeGetPlatformInfoResult, runtime_get_platform_info_result_callback, JSC_TYPE_VALUE, 0, G_TYPE_NONE);
        MAKE_FN(context, runtimeGetBrowserInfo, runtime_get_browser_info_callback, G_TYPE_NONE, 0, G_TYPE_NONE);
        MAKE_FN(context, runtimeGetBrowserInfoResult, runtime_get_browser_info_result_callback, JSC_TYPE_VALUE, 0, G_TYPE_NONE);

        MAKE_EVENT(context, "runtime", "onMessage");

        BIND_FN(context, "runtime", "sendMessage", "runtime.sendMessage = function (one, two, three) {\
    var no_two = (two === undefined || two === null ||                  \
                  (two.hasOwnProperty(\"includeTlsChannelId\") &&       \
                   two.keys.length <= 1));                              \
    var no_three = (three === undefined);                               \
    return new Promise(function (success, failure) {                    \
        try {                                                           \
            management.getSelf().then(function (info) {                 \
                var message = (no_two && no_three) ? one : two;         \
                var extensionId = (no_two && no_three) ? info.id : one; \
                runtimeSendMessage(extensionId, message);    \
                setTimeout(() => {                                      \
                    success(runtimeSendMessageResult());},     \
                           0);});                                       \
        } catch (error) {                                               \
            return failure(error);                                      \
        };                                                              \
    });                                                                 \
};                                                                      \
                                                                        \
runtime.sendMessage");
        BIND_FN(context, "runtime", "getPlatformInfo", "runtime.getPlatformInfo = function() {\
    return new Promise ((success, failure) => {                         \
        try {                                                           \
            runtimeGetPlatformInfo();                                   \
            setTimeout(() => {                                          \
                success(runtimeGetPlatformInfoResult());},              \
                        0);                                             \
        } catch (error) {                                               \
            return failure(error);                                      \
        };                                                              \
    });                                                                 \
};                                                                      \
                                                                        \
runtime.getPlatformInfo");
        BIND_FN(context, "runtime", "getBrowserInfo", "runtime.getBrowserInfo = function() {\
    return new Promise ((success, failure) => {                         \
        try {                                                           \
            runtimeGetBrowserInfo();                                   \
            setTimeout(() => {                                          \
                success(runtimeGetBrowserInfoResult());},              \
                        0);                                             \
        } catch (error) {                                               \
            return failure(error);                                      \
        };                                                              \
    });                                                                 \
};                                                                      \
                                                                        \
runtime.getBrowserInfo");

        char *runtime_get_manifest_js = malloc(sizeof(char) * 300);
        sprintf(runtime_get_manifest_js, "runtime.getManifest = function () { \
    return runtimeGetManifest(\"%s\");                                  \
};                                                                      \
                                                                        \
runtime.getManifest", extension_name);
        jsc_value_object_set_property(
                jsc_context_evaluate(context, "runtime", -1),
                "getManifest",
                jsc_context_evaluate(context, runtime_get_manifest_js, -1));
        jsc_value_object_set_property(
                jsc_context_evaluate(context, "browser", -1), "runtime",
                jsc_context_evaluate(context, "runtime", -1));
        free(runtime_get_manifest_js);
}
