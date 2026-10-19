(function () {
  var shims = globalThis.__TUNE_SHIMS || {};

  globalThis.require = function (name) {
    if (Object.prototype.hasOwnProperty.call(shims, name)) {
      return shims[name];
    }
    throw new Error("Cannot find module '" + name + "'");
  };

  globalThis.env = {
    getUserVariables: function () {
      return globalThis.__TUNE_USER_VARIABLES || {};
    },
  };

  globalThis.appVersion = '1.1.0';
  globalThis.os = 'linux';

  globalThis.__tune_invoke = async function (method, args) {
    var plugin = globalThis.__tune_plugin;
    var fn = plugin && plugin[method];
    if (typeof fn !== 'function') {
      throw new Error('Plugin does not implement ' + method);
    }
    return await fn.apply(plugin, args || []);
  };

  globalThis.__tune_metadata = function () {
    var plugin = globalThis.__tune_plugin || {};
    return JSON.stringify({
      platform: plugin.platform == null ? '' : String(plugin.platform),
      version: plugin.version == null ? '0.0.0' : String(plugin.version),
      author: plugin.author == null ? '' : String(plugin.author),
      description:
        plugin.description == null ? '' : String(plugin.description),
      hasSearch: typeof plugin.search === 'function',
      hasMediaSource: typeof plugin.getMediaSource === 'function',
      hasMusicInfo: typeof plugin.getMusicInfo === 'function',
      hasLyric: typeof plugin.getLyric === 'function',
      userVariables: Array.isArray(plugin.userVariables)
        ? plugin.userVariables
        : [],
    });
  };

  true;
})();
