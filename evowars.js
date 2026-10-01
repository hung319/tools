// ==UserScript==
// @name         Cerox-Adel Auto hit
// @namespace    http://tampermonkey.net/
// @version      2026-09-30-v24-predict-esp-target
// @description  AutoHit with exact engine weapon reach, length-aware smaller-target margin, corrected displayed level 24 reach, through-wall ESP overlay and predicted-target highlight
// @author       Peti
// @match        https://evowars.io/*
// @icon         https://www.google.com/s2/favicons?sz=64&domain=evowars.io
// @grant        none
// @license      MIT
// @downloadURL https://update.greasyfork.org/scripts/596769/Cerox-Adel%20Auto%20hit.user.js
// @updateURL https://update.greasyfork.org/scripts/596769/Cerox-Adel%20Auto%20hit.meta.js
// ==/UserScript==

var __awaiter =
  (this && this.__awaiter) ||
  function (thisArg, _arguments, P, generator) {
    function adopt(value) {
      return value instanceof P
        ? value
        : new P(function (resolve) {
            resolve(value);
          });
    }
    return new (P || (P = Promise))(function (resolve, reject) {
      function fulfilled(value) {
        try {
          step(generator.next(value));
        } catch (e) {
          reject(e);
        }
      }
      function rejected(value) {
        try {
          step(generator["throw"](value));
        } catch (e) {
          reject(e);
        }
      }
      function step(result) {
        result.done
          ? resolve(result.value)
          : adopt(result.value).then(fulfilled, rejected);
      }
      step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
  };
var __generator =
  (this && this.__generator) ||
  function (thisArg, body) {
    var _ = {
        label: 0,
        sent: function () {
          if (t[0] & 1) throw t[1];
          return t[1];
        },
        trys: [],
        ops: [],
      },
      f,
      y,
      t,
      g;
    return (
      (g = { next: verb(0), throw: verb(1), return: verb(2) }),
      typeof Symbol === "function" &&
        (g[Symbol.iterator] = function () {
          return this;
        }),
      g
    );
    function verb(n) {
      return function (v) {
        return step([n, v]);
      };
    }
    function step(op) {
      if (f) throw new TypeError("Generator is already executing.");
      while ((g && ((g = 0), op[0] && (_ = 0)), _))
        try {
          if (
            ((f = 1),
            y &&
              (t =
                op[0] & 2
                  ? y["return"]
                  : op[0]
                    ? y["throw"] || ((t = y["return"]) && t.call(y), 0)
                    : y.next) &&
              !(t = t.call(y, op[1])).done)
          )
            return t;
          if (((y = 0), t)) op = [op[0] & 2, t.value];
          switch (op[0]) {
            case 0:
            case 1:
              t = op;
              break;
            case 4:
              _.label++;
              return { value: op[1], done: false };
            case 5:
              _.label++;
              y = op[1];
              op = [0];
              continue;
            case 7:
              op = _.ops.pop();
              _.trys.pop();
              continue;
            default:
              if (
                !((t = _.trys), (t = t.length > 0 && t[t.length - 1])) &&
                (op[0] === 6 || op[0] === 2)
              ) {
                _ = 0;
                continue;
              }
              if (op[0] === 3 && (!t || (op[1] > t[0] && op[1] < t[3]))) {
                _.label = op[1];
                break;
              }
              if (op[0] === 6 && _.label < t[1]) {
                _.label = t[1];
                t = op;
                break;
              }
              if (t && _.label < t[2]) {
                _.label = t[2];
                _.ops.push(op);
                break;
              }
              if (t[2]) _.ops.pop();
              _.trys.pop();
              continue;
          }
          op = body.call(thisArg, _);
        } catch (e) {
          op = [6, e];
          y = 0;
        } finally {
          f = t = 0;
        }
      if (op[0] & 5) throw op[1];
      return { value: op[0] ? op[1] : void 0, done: true };
    }
  };
var __spreadArray =
  (this && this.__spreadArray) ||
  function (to, from, pack) {
    if (pack || arguments.length === 2)
      for (var i = 0, l = from.length, ar; i < l; i++) {
        if (ar || !(i in from)) {
          if (!ar) ar = Array.prototype.slice.call(from, 0, i);
          ar[i] = from[i];
        }
      }
    return to.concat(ar || Array.prototype.slice.call(from));
  };

(function () {
  "use strict";
  var wasm_bindCustom;

  // Global state — shared across modules
  window.modData = {};
  window.closePlayerUIDS = new Set();
  window.cr_setSuspended = function () {};
  window.autoHitEnabled = false;
  window.overlayMode = 0;
  window.hitBuffer = 0;
  window.debugClosestData = {};
  window.ping = 0;

  // Last-attacked target UID. Set only after a swing actually fires — used
  // for debug HUD and as a "just-hit" marker.
  window.currentTargetUID = undefined;
  // Predicted target UID. Re-evaluated every frame the autohit is on so the
  // ESP overlay can highlight the target the bot intends to swing at, even
  // while the swing is on cooldown. Cleared as soon as no enemy is in range.
  window.predictedTargetUID = undefined;

  // ESP (Extra Sensory Perception) — through-wall awareness overlay.
  // Toggled with [E]. Draws a box, nickname, internal level and live distance
  // on top of every other player using the same overlay canvas as the weapon
  // reach circles. All knobs are exposed via window.espSettings so they can be
  // tweaked from the console without reloading the script.
  window.espEnabled = false;
  window.espSettings = {
    showBoxes: true,
    showNames: true,
    showLevel: true,
    showDistance: true,
    showSnaplines: true,
    showTeammates: true,
    showHpBar: true,
    maxDistance: 20000,
    // When true, ESP ignores distance-based culling for the current autohit
    // target so the highlight never disappears while the bot is tracking it.
    alwaysShowCurrentTarget: true,
    enemyBoxColor: "rgba(244, 67, 54, 0.9)",
    teammateBoxColor: "rgba(76, 175, 80, 0.9)",
    nameTextColor: "#ffffff",
    distanceTextColor: "#ffe082",
    textShadow: "rgba(0,0,0,0.9)",
    snaplineEnemyColor: "rgba(244, 67, 54, 0.28)",
    snaplineTeammateColor: "rgba(76, 175, 80, 0.18)",
    hpBarBackground: "rgba(0,0,0,0.55)",
    hpBarFill: "rgba(76, 175, 80, 0.9)",
    hpBarLowFill: "rgba(244, 67, 54, 0.9)",
    boxThickness: 1.5,
    cornerLength: 14,
    fontSize: 12,

    // Current-autohit-target highlight. The bot exposes the predicted
    // target on window.predictedTargetUID; the overlay renders it with a
    // brighter snapline, a thicker border, and an extra "★ TARGET" label.
    // Colour is bright cyan so it stands out from red (enemy), green
    // (teammate) and orange (big-target) lines on any background.
    highlightCurrentTarget: true,
    currentTargetSnaplineColor: "rgba(0, 255, 255, 1.0)",
    currentTargetSnaplineWidth: 4.5,
    currentTargetGlowColor: "rgba(0, 255, 255, 0.45)",
    currentTargetGlowWidth: 12,
    currentTargetBoxColor: "rgba(0, 255, 255, 0.95)",
    currentTargetBoxThicknessMultiplier: 2.8,
    currentTargetLabel: "★ TARGET",
    currentTargetLabelColor: "#00ffff",

    // Big Target mode visualisation. The bot only attacks enemies within 5
    // levels of your own; this overlay mode makes that filter visible.
    //   'highlight' = eligible enemies get an orange border, ineligible are dim
    //   'dim'       = all enemies shown, ineligible are dimmed
    //   'hide'      = only eligible enemies are drawn
    bigTargetHighlight: "highlight",
    bigTargetEligibleColor: "rgba(255, 152, 0, 0.95)",
    bigTargetSnaplineEligibleColor: "rgba(255, 152, 0, 0.55)",
    bigTargetIneligibleAlpha: 0.3,

    // Level badge — a small filled square in the top-left of the box that
    // shows the player's internal level as a single number (level + 1, the
    // displayed character number). Helps spot high-level threats at a
    // glance without parsing the [L21] suffix in the nickname label.
    showLevelBadge: true,
    levelBadgeSize: 22,
    levelBadgeFontSize: 12,
    levelBadgeTextColor: "#ffffff",
    levelBadgeShadow: "rgba(0, 0, 0, 0.85)",

    // Level diff — shows the difference between the enemy level and the
    // local player level as a compact "+N" / "-N" tag in the top-right
    // corner. Colour is threat-coded: red for higher, yellow for equal,
    // green for lower. The "danger" threshold (+5 or more) is highlighted
    // in bright red so a tough matchup is obvious before contact.
    showLevelDiff: true,
    levelDiffFontSize: 12,
    levelDiffDangerThreshold: 5,
    levelDiffHigherColor: "rgba(244, 67, 54, 0.95)",   // enemy is stronger
    levelDiffEqualColor:  "rgba(255, 235, 59, 0.95)",  // same level
    levelDiffLowerColor:  "rgba(76, 175, 80, 0.95)",   // enemy is weaker
    levelDiffDangerColor: "rgba(255, 82, 82, 1.0)",    // very strong enemy

    // HP text — show "current/max" as text below the HP bar. Off by
    // default because the bar already encodes the ratio and the text
    // would clutter the overlay. Enable if you prefer precise values.
    showHpText: false,
    hpTextFontSize: 10,
    hpTextColor: "#ffffff",
    hpTextLowColor: "rgba(255, 200, 200, 0.95)",

    // Off-screen indicator. When true, players whose world position is
    // outside the camera view get a small triangle at the screen edge
    // pointing toward them, with name + level + distance on the label.
    // The current autohit target is always rendered (it would defeat the
    // purpose if the bot was tracking a player the user couldn't locate).
    showOffscreenIndicators: true,
    offscreenIndicatorEnemyColor: "rgba(255, 152, 0, 0.95)",
    offscreenIndicatorTeammateColor: "rgba(76, 175, 80, 0.95)",
    offscreenIndicatorCurrentTargetColor: "rgba(0, 255, 255, 0.95)",
    offscreenIndicatorEligibleBigTargetColor: "rgba(255, 152, 0, 0.95)",
    offscreenIndicatorShowName: true,
    offscreenIndicatorShowLevel: true,
    offscreenIndicatorShowDistance: true,
    offscreenIndicatorShowArrow: true,
    offscreenIndicatorShowLine: true,
    offscreenIndicatorSize: 10,
    offscreenIndicatorMargin: 40,
    offscreenIndicatorFontSize: 12,
    offscreenIndicatorArrowLength: 32,
    offscreenIndicatorLineLength: 60,
    offscreenIndicatorShadow: "rgba(0,0,0,0.85)"
  };

  window.setEspEnabled = function (enabled) {
    window.espEnabled = !!enabled;
    console.log("[AutoHit] ESP overlay:", window.espEnabled ? "ON" : "OFF");
    if (typeof updateStatusDisplay === "function") updateStatusDisplay();
  };

  // Sword reach fallback table and stable per-character swing offsets.
  // distance: legacy fallback only; live collision-polygon reach remains primary.
  // degrees: stable offset added to atan2(targetDirection). Values combine the
  // existing visually tuned table with conservative updates from swing logs and
  // in-game A/B testing. We deliberately do NOT calculate this live per frame.
  window.swordLevelTable = {
    0:  { distance: 93, degrees: 130 },
    1:  { distance: 123, degrees: 130 },
    2:  { distance: 123, degrees: 130 },
    3:  { distance: 135, degrees: 135 },
    4:  { distance: 165, degrees: 142 },
    5:  { distance: 173, degrees: 140 },
    6:  { distance: 180, degrees: 140 },
    7:  { distance: 233, degrees: 142 },
    8:  { distance: 255, degrees: 143 },
    9:  { distance: 263, degrees: 145 },
    10: { distance: 310, degrees: 138 },
    11: { distance: 320, degrees: 140 },
    12: { distance: 325, degrees: 137 },
    13: { distance: 350, degrees: 145 },
    14: { distance: 405, degrees: 135 },
    15: { distance: 392, degrees: 142 },
    16: { distance: 410, degrees: 150 },
    17: { distance: 470, degrees: 142 },
    18: { distance: 465, degrees: 135 },
    19: { distance: 520, degrees: 129 },
    20: { distance: 530, degrees: 134 },
    21: { distance: 550, degrees: 135 },
    22: { distance: 550, degrees: 132 },
    23: { distance: 620, degrees: 138 },
    24: { distance: 645, degrees: 140 },
    25: { distance: 660, degrees: 140 },
    26: { distance: 755, degrees: 128 },
    27: { distance: 750, degrees: 132 },
    28: { distance: 705, degrees: 140 },
    29: { distance: 710, degrees: 140 },
    30: { distance: 750, degrees: 140 },
    31: { distance: 790, degrees: 136 },
    32: { distance: 815, degrees: 137 },
    33: { distance: 830, degrees: 140 },
    34: { distance: 848, degrees: 137 },
    35: { distance: 910, degrees: 127 },
    36: { distance: 1030, degrees: 130 },
    37: { distance: 1090, degrees: 123 },
    38: { distance: 1090, degrees: 124 },
    39: { distance: 1100, degrees: 125 },
    40: { distance: 1170, degrees: 121 }
  };

  // Swing cooldown in ms per internal runtime level.
  // Measured values use the compact cooldown probe. Missing levels keep the
  // previous fallback until they are measured directly. Values are rounded
  // conservatively so the client does not reset its own timer on a request
  // sent just before the server-side cooldown expires.
  window.cooldownTable = {
    0:  400, 1:  420, 2:  450, 3:  500, 4:  560,
    5:  680, 6:  750, 7:  850, 8:  950, 9:  1060,
    10: 1210, 11: 1290, 12: 1350, 13: 1440,
    14: 1560, 15: 1660, 16: 1780, 17: 1890, 18: 1970,
    19: 2110, 20: 2210, 21: 2265, 22: 2425, 23: 2480,
    24: 2550, 25: 2700, 26: 2770, 27: 2850,
    28: 3000, 29: 3100, 30: 3150, 31: 3340, 32: 3400,
    33: 3450, 34: 3600, 35: 3650, 36: 3650,
    37: 3800, 38: 3750, 39: 3950, 40: 3750
  };

  // wasm stuff
  (function () {
    var __exports = {};
    var script_src = "https://evowars.io/wasm_network.js";

    var wasm = undefined;
    var heap = new Array(128).fill(undefined);
    heap.push(undefined, null, true, false);
    function getObject(idx) {
      return heap[idx];
    }
    var heap_next = heap.length;
    function dropObject(idx) {
      if (idx < 132) return;
      heap[idx] = heap_next;
      heap_next = idx;
    }
    function takeObject(idx) {
      var ret = getObject(idx);
      dropObject(idx);
      return ret;
    }
    function addHeapObject(obj) {
      if (heap_next === heap.length) heap.push(heap.length + 1);
      var idx = heap_next;
      heap_next = heap[idx];
      heap[idx] = obj;
      return idx;
    }
    function isLikeNone(x) {
      return x === undefined || x === null;
    }
    var cachedFloat64Memory0 = null;
    function getFloat64Memory0() {
      if (
        cachedFloat64Memory0 === null ||
        cachedFloat64Memory0.byteLength === 0
      ) {
        cachedFloat64Memory0 = new Float64Array(wasm.memory.buffer);
      }
      return cachedFloat64Memory0;
    }
    var cachedInt32Memory0 = null;
    function getInt32Memory0() {
      if (cachedInt32Memory0 === null || cachedInt32Memory0.byteLength === 0) {
        cachedInt32Memory0 = new Int32Array(wasm.memory.buffer);
      }
      return cachedInt32Memory0;
    }
    var cachedTextDecoder =
      typeof TextDecoder !== "undefined"
        ? new TextDecoder("utf-8", { ignoreBOM: true, fatal: true })
        : {
            decode: function () {
              throw Error("TextDecoder not available");
            },
          };
    if (typeof TextDecoder !== "undefined") {
      cachedTextDecoder.decode();
    }
    var cachedUint8Memory0 = null;
    function getUint8Memory0() {
      if (cachedUint8Memory0 === null || cachedUint8Memory0.byteLength === 0) {
        cachedUint8Memory0 = new Uint8Array(wasm.memory.buffer);
      }
      return cachedUint8Memory0;
    }
    function getStringFromWasm0(ptr, len) {
      ptr = ptr >>> 0;
      return cachedTextDecoder.decode(
        getUint8Memory0().subarray(ptr, ptr + len),
      );
    }
    function debugString(val) {
      var type = typeof val;
      if (type == "number" || type == "boolean" || val == null) {
        return "".concat(val);
      }
      if (type == "string") {
        return '"'.concat(val, '"');
      }
      if (type == "symbol") {
        var description = val.description;
        if (description == null) {
          return "Symbol";
        } else {
          return "Symbol(".concat(description, ")");
        }
      }
      if (type == "function") {
        var name_1 = val.name;
        if (typeof name_1 == "string" && name_1.length > 0) {
          return "Function(".concat(name_1, ")");
        } else {
          return "Function";
        }
      }
      if (Array.isArray(val)) {
        var length_1 = val.length;
        var debug_1 = "[";
        if (length_1 > 0) {
          debug_1 += debugString(val[0]);
        }
        for (var i = 1; i < length_1; i++) {
          debug_1 += ", " + debugString(val[i]);
        }
        debug_1 += "]";
        return debug_1;
      }
      var builtInMatches = /\[object ([^\]]+)\]/.exec(toString.call(val));
      var className;
      if (builtInMatches.length > 1) {
        className = builtInMatches[1];
      } else {
        return toString.call(val);
      }
      if (className == "Object") {
        try {
          return "Object(" + JSON.stringify(val) + ")";
        } catch (_) {
          return "Object";
        }
      }
      if (val instanceof Error) {
        return ""
          .concat(val.name, ": ")
          .concat(val.message, "\n")
          .concat(val.stack);
      }
      return className;
    }
    var WASM_VECTOR_LEN = 0;
    var cachedTextEncoder =
      typeof TextEncoder !== "undefined"
        ? new TextEncoder()
        : {
            encode: function (params_) {
              throw Error("TextEncoder not available");
            },
          };
    var encodeString =
      function (arg, view) {
        var buf = cachedTextEncoder.encode(arg);
        view.set(buf);
        return {
          read: arg.length,
          written: buf.length,
        };
      };
    function passStringToWasm0(arg, malloc, realloc) {
      if (realloc === undefined) {
        var buf = cachedTextEncoder.encode(arg);
        var ptr_1 = malloc(buf.length, 1) >>> 0;
        getUint8Memory0()
          .subarray(ptr_1, ptr_1 + buf.length)
          .set(buf);
        WASM_VECTOR_LEN = buf.length;
        return ptr_1;
      }
      var len = arg.length;
      var ptr = malloc(len, 1) >>> 0;
      var mem = getUint8Memory0();
      var offset = 0;
      for (; offset < len; offset++) {
        var code = arg.charCodeAt(offset);
        if (code > 0x7f) break;
        mem[ptr + offset] = code;
      }
      if (offset !== len) {
        if (offset !== 0) {
          arg = arg.slice(offset);
        }
        ptr = realloc(ptr, len, (len = offset + arg.length * 3), 1) >>> 0;
        var view = getUint8Memory0().subarray(ptr + offset, ptr + len);
        var ret = encodeString(arg, view);
        offset += ret.written;
        ptr = realloc(ptr, len, offset, 1) >>> 0;
      }
      WASM_VECTOR_LEN = offset;
      return ptr;
    }
    var CLOSURE_DTORS =
      typeof FinalizationRegistry === "undefined"
        ? { register: function () {}, unregister: function () {} }
        : new FinalizationRegistry(function (state) {
            wasm.__wbindgen_export_2.get(state.dtor)(state.a, state.b);
          });
    function makeClosure(arg0, arg1, dtor, f) {
      var state = { a: arg0, b: arg1, cnt: 1, dtor: dtor };
      var real = function () {
        var args = [];
        for (var _i = 0; _i < arguments.length; _i++) {
          args[_i] = arguments[_i];
        }
        state.cnt++;
        try {
          return f.apply(
            void 0,
            __spreadArray([state.a, state.b], args, false),
          );
        } finally {
          if (--state.cnt === 0) {
            wasm.__wbindgen_export_2.get(state.dtor)(state.a, state.b);
            state.a = 0;
            CLOSURE_DTORS.unregister(state);
          }
        }
      };
      real.original = state;
      CLOSURE_DTORS.register(real, state, state);
      return real;
    }
    var nums;
    function __wbg_adapter_28(arg0, arg1, arg2) {
      nums = { arg0: arg0, arg1: arg1 };
      wasm.__wbindgen_export_3(arg0, arg1, addHeapObject(arg2));
    }
    __exports.adapter = __wbg_adapter_28;
    __exports.getNums = function () {
      return nums;
    };
    __exports.startC = function () {
      wasm.start();
    };
    __exports.get_angleC = function () {
      var ret = wasm.get_angle();
      return ret >>> 0;
    };
    __exports.adjustC = function (ts) {
      var ret = wasm.adjust(ts);
      return ret >>> 0;
    };
    function handleError(f, args) {
      try {
        return f.apply(this, args);
      } catch (e) {
        wasm.__wbindgen_export_4(addHeapObject(e));
      }
    }
    var WasmNetworkFinalization =
      typeof FinalizationRegistry === "undefined"
        ? { register: function () {}, unregister: function () {} }
        : new FinalizationRegistry(function (ptr) {
            return wasm.__wbg_wasmnetwork_free(ptr >>> 0);
          });
    var WasmNetwork = (function () {
      function WasmNetwork() {}
      WasmNetwork.__wrap = function (ptr) {
        ptr = ptr >>> 0;
        var obj = Object.create(WasmNetwork.prototype);
        obj.__wbg_ptr = ptr;
        WasmNetworkFinalization.register(obj, obj.__wbg_ptr, obj);
        return obj;
      };
      WasmNetwork.prototype.__destroy_into_raw = function () {
        var ptr = this.__wbg_ptr;
        this.__wbg_ptr = 0;
        WasmNetworkFinalization.unregister(this);
        return ptr;
      };
      WasmNetwork.prototype.free = function () {
        var ptr = this.__destroy_into_raw();
        wasm.__wbg_wasmnetwork_free(ptr);
      };
      WasmNetwork.new = function () {
        var ret = wasm.wasmnetwork_new();
        return ret === 0 ? undefined : WasmNetwork.__wrap(ret);
      };
      return WasmNetwork;
    })();
    __exports.WasmNetwork = WasmNetwork;
    function __wbg_load(module, imports) {
      return __awaiter(this, void 0, void 0, function () {
        var e_1, bytes, instance;
        return __generator(this, function (_a) {
          switch (_a.label) {
            case 0:
              if (
                !(typeof Response === "function" && module instanceof Response)
              )
                return [3, 7];
              if (!(typeof WebAssembly.instantiateStreaming === "function"))
                return [3, 4];
              _a.label = 1;
            case 1:
              _a.trys.push([1, 3, , 4]);
              return [
                4,
                WebAssembly.instantiateStreaming(module, imports),
              ];
            case 2:
              return [2, _a.sent()];
            case 3:
              e_1 = _a.sent();
              if (module.headers.get("Content-Type") != "application/wasm") {} else {
                throw e_1;
              }
              return [3, 4];
            case 4:
              return [4, module.arrayBuffer()];
            case 5:
              bytes = _a.sent();
              return [4, WebAssembly.instantiate(bytes, imports)];
            case 6:
              return [2, _a.sent()];
            case 7:
              return [4, WebAssembly.instantiate(module, imports)];
            case 8:
              instance = _a.sent();
              if (instance instanceof WebAssembly.Instance) {
                return [2, { instance: instance, module: module }];
              } else {
                return [2, instance];
              }
            case 9:
              return [2];
          }
        });
      });
    }
    function __wbg_get_imports() {
      var imports = {};
      imports.wbg = {};
      imports.wbg.__wbindgen_object_drop_ref = function (arg0) {
        takeObject(arg0);
      };
      imports.wbg.__wbindgen_cb_drop = function (arg0) {
        var obj = takeObject(arg0).original;
        if (obj.cnt-- == 1) {
          obj.a = 0;
          return true;
        }
        var ret = false;
        return ret;
      };
      imports.wbg.__wbindgen_object_clone_ref = function (arg0) {
        var ret = getObject(arg0);
        return addHeapObject(ret);
      };
      imports.wbg.__wbg_instanceof_Window_cee7a886d55e7df5 = function (arg0) {
        var result;
        try {
          result = getObject(arg0) instanceof Window;
        } catch (_) {
          result = false;
        }
        var ret = result;
        return ret;
      };
      imports.wbg.__wbg_document_eb7fd66bde3ee213 = function (arg0) {
        var ret = getObject(arg0).document;
        return isLikeNone(ret) ? 0 : addHeapObject(ret);
      };
      imports.wbg.__wbg_addEventListener_543dec6cfdd61f52 = function () {
        return handleError(function (arg0, arg1, arg2, arg3, arg4) {
          getObject(arg0).addEventListener(
            getStringFromWasm0(arg1, arg2),
            getObject(arg3),
            arg4 !== 0,
          );
        }, arguments);
      };
      imports.wbg.__wbg_innerWidth_024833561ebc9741 = function () {
        return handleError(function (arg0) {
          var ret = getObject(arg0).innerWidth;
          return addHeapObject(ret);
        }, arguments);
      };
      imports.wbg.__wbindgen_number_get = function (arg0, arg1) {
        var obj = getObject(arg1);
        var ret = typeof obj === "number" ? obj : undefined;
        getFloat64Memory0()[arg0 / 8 + 1] = isLikeNone(ret) ? 0 : ret;
        getInt32Memory0()[arg0 / 4 + 0] = !isLikeNone(ret);
      };
      imports.wbg.__wbg_innerHeight_a9719febb72ddaf3 = function () {
        return handleError(function (arg0) {
          var ret = getObject(arg0).innerHeight;
          return addHeapObject(ret);
        }, arguments);
      };
      imports.wbg.__wbg_x_f87383daeae890c8 = function (arg0) {
        var ret = getObject(arg0).x;
        return ret;
      };
      imports.wbg.__wbg_y_f3f4193027920b58 = function (arg0) {
        var ret = getObject(arg0).y;
        return ret;
      };
      imports.wbg.__wbg_isTrusted_613dfe31b7a1bf55 = function (arg0) {
        return true;
      };
      imports.wbg.__wbg_now_ba25f0a487340763 = function () {
        var ret = Date.now();
        return ret;
      };
      imports.wbg.__wbindgen_number_new = function (arg0) {
        var ret = arg0;
        return addHeapObject(ret);
      };
      imports.wbg.__wbg_new_a9d80688888b4894 = function (arg0) {
        var ret = new Date(getObject(arg0));
        return addHeapObject(ret);
      };
      imports.wbg.__wbg_getUTCHours_a3c03b1737ed85e5 = function (arg0) {
        var ret = getObject(arg0).getUTCHours();
        return ret;
      };
      imports.wbg.__wbg_getUTCMinutes_5287972f1da23774 = function (arg0) {
        var ret = getObject(arg0).getUTCMinutes();
        return ret;
      };
      imports.wbg.__wbg_crypto_d05b68a3572bb8ca = function (arg0) {
        var ret = getObject(arg0).crypto;
        return addHeapObject(ret);
      };
      imports.wbg.__wbindgen_is_object = function (arg0) {
        var val = getObject(arg0);
        var ret = typeof val === "object" && val !== null;
        return ret;
      };
      imports.wbg.__wbg_process_b02b3570280d0366 = function (arg0) {
        var ret = getObject(arg0).process;
        return addHeapObject(ret);
      };
      imports.wbg.__wbg_versions_c1cb42213cedf0f5 = function (arg0) {
        var ret = getObject(arg0).versions;
        return addHeapObject(ret);
      };
      imports.wbg.__wbg_node_43b1089f407e4ec2 = function (arg0) {
        var ret = getObject(arg0).node;
        return addHeapObject(ret);
      };
      imports.wbg.__wbindgen_is_string = function (arg0) {
        var ret = typeof getObject(arg0) === "string";
        return ret;
      };
      imports.wbg.__wbg_msCrypto_10fc94afee92bd76 = function (arg0) {
        var ret = getObject(arg0).msCrypto;
        return addHeapObject(ret);
      };
      imports.wbg.__wbg_newwithlength_0d03cef43b68a530 = function (arg0) {
        var ret = new Uint8Array(arg0 >>> 0);
        return addHeapObject(ret);
      };
      imports.wbg.__wbg_require_9a7e0f667ead4995 = function () {
        return handleError(function () {
          var ret = module.require;
          return addHeapObject(ret);
        }, arguments);
      };
      imports.wbg.__wbindgen_is_function = function (arg0) {
        var ret = typeof getObject(arg0) === "function";
        return ret;
      };
      imports.wbg.__wbindgen_string_new = function (arg0, arg1) {
        var ret = getStringFromWasm0(arg0, arg1);
        return addHeapObject(ret);
      };
      imports.wbg.__wbg_call_67f2111acd2dfdb6 = function () {
        return handleError(function (arg0, arg1, arg2) {
          var ret = getObject(arg0).call(getObject(arg1), getObject(arg2));
          return addHeapObject(ret);
        }, arguments);
      };
      imports.wbg.__wbindgen_memory = function () {
        var ret = wasm.memory;
        return addHeapObject(ret);
      };
      imports.wbg.__wbg_buffer_b914fb8b50ebbc3e = function (arg0) {
        var ret = getObject(arg0).buffer;
        return addHeapObject(ret);
      };
      imports.wbg.__wbg_newwithbyteoffsetandlength_0de9ee56e9f6ee6e = function (
        arg0,
        arg1,
        arg2,
      ) {
        var ret = new Uint8Array(getObject(arg0), arg1 >>> 0, arg2 >>> 0);
        return addHeapObject(ret);
      };
      imports.wbg.__wbg_randomFillSync_b70ccbdf4926a99d = function () {
        return handleError(function (arg0, arg1) {
          getObject(arg0).randomFillSync(takeObject(arg1));
        }, arguments);
      };
      imports.wbg.__wbg_subarray_adc418253d76e2f1 = function (
        arg0,
        arg1,
        arg2,
      ) {
        var ret = getObject(arg0).subarray(arg1 >>> 0, arg2 >>> 0);
        return addHeapObject(ret);
      };
      imports.wbg.__wbg_getRandomValues_7e42b4fb8779dc6d = function () {
        return handleError(function (arg0, arg1) {
          getObject(arg0).getRandomValues(getObject(arg1));
        }, arguments);
      };
      imports.wbg.__wbg_new_b1f2d6842d615181 = function (arg0) {
        var ret = new Uint8Array(getObject(arg0));
        return addHeapObject(ret);
      };
      imports.wbg.__wbg_set_7d988c98e6ced92d = function (arg0, arg1, arg2) {
        getObject(arg0).set(getObject(arg1), arg2 >>> 0);
      };
      imports.wbg.__wbg_self_05040bd9523805b9 = function () {
        return handleError(function () {
          var ret = self.self;
          return addHeapObject(ret);
        }, arguments);
      };
      imports.wbg.__wbg_window_adc720039f2cb14f = function () {
        return handleError(function () {
          var ret = window.window;
          return addHeapObject(ret);
        }, arguments);
      };
      imports.wbg.__wbg_globalThis_622105db80c1457d = function () {
        return handleError(function () {
          var ret = globalThis.globalThis;
          return addHeapObject(ret);
        }, arguments);
      };
      imports.wbg.__wbg_global_f56b013ed9bcf359 = function () {
        return handleError(function () {
          var ret = global.global;
          return addHeapObject(ret);
        }, arguments);
      };
      imports.wbg.__wbindgen_is_undefined = function (arg0) {
        var ret = getObject(arg0) === undefined;
        return ret;
      };
      imports.wbg.__wbg_newnoargs_cfecb3965268594c = function (arg0, arg1) {
        var ret = new Function(getStringFromWasm0(arg0, arg1));
        return addHeapObject(ret);
      };
      imports.wbg.__wbg_call_3f093dd26d5569f8 = function () {
        return handleError(function (arg0, arg1) {
          var ret = getObject(arg0).call(getObject(arg1));
          return addHeapObject(ret);
        }, arguments);
      };
      imports.wbg.__wbindgen_debug_string = function (arg0, arg1) {
        var ret = debugString(getObject(arg1));
        var ptr1 = passStringToWasm0(
          ret,
          wasm.__wbindgen_export_0,
          wasm.__wbindgen_export_1,
        );
        var len1 = WASM_VECTOR_LEN;
        getInt32Memory0()[arg0 / 4 + 1] = len1;
        getInt32Memory0()[arg0 / 4 + 0] = ptr1;
      };
      imports.wbg.__wbindgen_throw = function (arg0, arg1) {
        throw new Error(getStringFromWasm0(arg0, arg1));
      };
      imports.wbg.__wbindgen_closure_wrapper58 = function (arg0, arg1, arg2) {
        var ret = makeClosure(arg0, arg1, 23, __wbg_adapter_28);
        return addHeapObject(ret);
      };
      imports.wbg.__wbindgen_closure_wrapper59 = function (arg0, arg1, arg2) {
        var ret = makeClosure(arg0, arg1, 23, __wbg_adapter_28);
        return addHeapObject(ret);
      };
      imports.wbg.__wbindgen_closure_wrapper60 = function (arg0, arg1, arg2) {
        var ret = makeClosure(arg0, arg1, 23, __wbg_adapter_28);
        return addHeapObject(ret);
      };
      return imports;
    }
    function __wbg_init_memory(imports, maybe_memory) {}
    function __wbg_finalize_init(instance, module) {
      wasm = instance.exports;
      __wbg_init.__wbindgen_wasm_module = module;
      cachedFloat64Memory0 = null;
      cachedInt32Memory0 = null;
      cachedUint8Memory0 = null;
      wasm.__wbindgen_start();
      return wasm;
    }
    function initSync(module) {
      if (wasm !== undefined) return wasm;
      var imports = __wbg_get_imports();
      __wbg_init_memory(imports);
      if (!(module instanceof WebAssembly.Module)) {
        module = new WebAssembly.Module(module);
      }
      var instance = new WebAssembly.Instance(module, imports);
      return __wbg_finalize_init(instance, module);
    }
    var __wbg_init = function (input) {
      return __awaiter(this, void 0, void 0, function () {
        var imports, _a, instance, module, _b;
        return __generator(this, function (_c) {
          switch (_c.label) {
            case 0:
              if (wasm !== undefined) return [2, wasm];
              if (
                typeof input === "undefined" &&
                typeof script_src !== "undefined"
              ) {
                input = script_src.replace(/\.js\?.*/, "_bg.wasm");
                input = "https://evowars.io/wasm_network_bg.wasm";
              }
              imports = __wbg_get_imports();
              if (
                typeof input === "string" ||
                (typeof Request === "function" && input instanceof Request) ||
                (typeof URL === "function" && input instanceof URL)
              ) {
                input = fetch(input);
              }
              __wbg_init_memory(imports);
              _b = __wbg_load;
              return [4, input];
            case 1:
              return [4, _b.apply(void 0, [_c.sent(), imports])];
            case 2:
              ((_a = _c.sent()),
                (instance = _a.instance),
                (module = _a.module));
              return [2, __wbg_finalize_init(instance, module)];
          }
        });
      });
    };
    wasm_bindCustom = Object.assign(
      __wbg_init,
      { initSync: initSync },
      __exports,
    );
  })();

  function mainApp() {
    var wsWorker;
    var isWSReady = false;
    var powerWS = window.cr.plugins_.NSG_PowerWS.prototype;

    // Prediction-free mode: no velocity estimation, TTC solving or future-position extrapolation.
    // The trigger uses only the current engine-frame center distance and the measured live sword reach.
    var INDEX_ANGLE_VAR = 15;

    window.netTuning = {
      // Multiplier on the level-based body radius. >1.0 makes the bot think
      // the enemy is bigger (fires earlier), <1.0 makes it think smaller.
      targetRadiusScale: 1.0,

      // Fixed pixel offset added to the body radius after scaling. 0 keeps
      // the trigger conservative — combined with a moderate pre-fire offset
      // below it gives a balanced "fires slightly early but not early
      // enough to whiff" behaviour. Bump to 5–10 if you still see late hits
      // against small or fast targets.
      targetRadiusPadding: 0,

      // Pre-fire offset. Negative = fire before perfect geometric contact.
      // -8 px compensates for the swing travel time vs the strict
      // centre-distance trigger. Going more negative (-12, -15) starts
      // landing hits before the target is in range and the swing passes
      // them — use those only if your target keeps slipping out at the
      // last frame.
      currentDistanceInset: -8,

      // Velocity-based aim lead for non-heuristic mode. Uses the per-player
      // motion snapshots to push the click point toward the target's predicted
      // position by the time the swing actually connects. The lead window is
      // bounded by aimLeadMaxMs so fast swing speeds cannot over-aim.
      aimLeadEnabled: true,
      aimLeadBaseMs: 40,
      aimLeadPingScale: 0.4,
      aimLeadMaxMs: 130,

      // Swing angle offset (degrees) added to atan2(targetDirection) before
      // the click is sent. The per-character table at the top of the file
      // is the source of truth, but those values can drift as the game ships
      // updates. Use these overrides to retune live in the console:
      //   netTuning.swingDegreesOverride = 140  // force this for every swing
      //   netTuning.swingDegreesOffset  = 5    // add 5° to per-character default
      // The default (null / 0) keeps the per-character table values intact.
      // Use window.swingProbe(deg) to log the active value before/after.
      swingDegreesOverride: null,
      swingDegreesOffset: 0,

      // Target selection within the trigger range.
      //   'closest'       = nearest enemy in range (intuitive FFA behaviour)
      //   'highest-level' = biggest character in range (legacy behaviour)
      // Ties in 'closest' mode are broken by the higher internal level.
      targetSelection: "closest",

      // Level filter applied before the range check.
      //   'all'             = no level restriction (default — attack anyone)
      //   'big-only'        = only attack enemies within 5 levels of your own
      //   'small-only'      = only attack smaller enemies
      //   'bigger-only'     = only attack bigger enemies
      //   'same-only'       = only attack same internal level
      //   'same-or-smaller' = attack same or smaller
      //   'same-or-bigger'  = attack same or bigger
      // The [C] Big Target key sets this to 'big-only' / 'all'.
      levelFilter: "all",

      // Reach-aware pre-fire. When myWeaponReach is below reachPrefireReference,
      // the negative currentDistanceInset is scaled UP so short swords get a
      // relatively larger pre-fire. Without this, level-0/1 swords fire too
      // late against a target that slips past before the swing connects.
      //   93 px reach  -> scale ~2.7x (e.g. -8 base becomes -22 px)
      //   250 px reach -> scale 1.0x (unchanged)
      //   1100 px reach -> scale 1.0x (unchanged)
      reachAwarePrefire: true,
      reachPrefireReference: 250,
      reachPrefireMin: 50,

      // Body-radius bonus for lower-level targets. A small bonus is added
      // to totalHitRadius so the trigger has a safety margin against smaller
      // enemies that are easier to hit dead-on.
      //   level diff 1  -> +1.5 px
      //   level diff 5  -> +7.5 px
      //   level diff 8+ -> +12 px (cap)
      smallerTargetBodyBonusPerLevel: 1.5,
      smallerTargetBodyBonusCap: 12,

      // Time-based closing lead. The pre-fire window scales with ping so
      // higher-latency connections get a proportionally larger lead.
      //   preFireMs = min(maxPreFireMs, basePreFireMs + ping * pingScale)
      // closingLeadPx = min(cap, radialClosingSpeed * preFireMs/1000 * scale)
      preFireBaseMs: 35,
      preFirePingScale: 0.5,
      preFireMaxMs: 120,
      closingLeadScale: 0.5,
      closingLeadCap: 40,

      // Smart trigger — adds an extra layer on top of the geometry check so
      // a swing only fires when it is actually going to connect. Three
      // checks run after the basic distance check passes:
      //
      //   1. Multi-frame confirmation. The target must have been inside
      //      the trigger zone for at least smartTriggerFrames consecutive
      //      frames. This debounces single-frame false positives caused
      //      by ping spikes, sprite rounding, or tangential "graze" frames.
      //
      //   2. Predictive geometry. The target is projected to where it
      //      will be at contact time (smartTriggerContactMs from now,
      //      adjusted for ping). If the projected position is already
      //      outside the reach, the swing would miss — reject.
      //
      //   3. Tangential motion guard. If the target is moving mostly
      //      perpendicular to the attack line (low closing/total speed
      //      ratio), require more frames before firing. Head-on targets
      //      can fire after 2 frames; sideways targets need 4+.
      smartTriggerEnabled: true,
      smartTriggerFrames: 2,
      smartTriggerContactMs: 100,
      smartTriggerContactPingScale: 0.3,
      smartTriggerTangentialRatio: 0.3,
      smartTriggerTangentialFrames: 4,
      smartTriggerOutOfRangeTimeout: 150,
      smartTriggerMaxTracked: 200,

      // When true, the smart trigger exposes the predicted aim vector
      // back to executeAttack() so the click leads the target to its
      // expected contact position. Disable for legacy current-position aim.
      smartTriggerUsePredictedAim: true
    };

    // ======================================================
    // HEURISTIC INSETS (merged into autohit)
    //
    // The standalone visibleHeuristic A/B mode was retired. Its useful
    // insets (level-relation, contact inset, long-reach extra inset, and
    // the smaller-target guaranteed-penetration ceiling) are now applied
    // unconditionally inside the AllLoop trigger calculation. The tuning
    // object is kept so users can still tweak the values from the console:
    //   window.visibleHeuristicTuning.strongerAttackerInsetPerLevel = 6
    //   window.visibleHeuristicTuning.contactInsetVsSmallerTarget = 10
    // The smart trigger (added separately) provides the predictive aim,
    // multi-frame confirmation and tangential motion guard.
    // ======================================================
    window.visibleHeuristicTuning = {
      // d2 is not visible in the screenshot, so the short extrapolation horizon
      // remains our A/B-test parameter rather than a claimed copied constant.
      horizonMs: 42,
      maxHorizonMs: 72,

      // Snapshot velocity filtering. Repeated identical snapshots do not reset
      // the timestamp of the last real movement sample.
      velocityAlpha: 0.55,
      maxTrackedSpeed: 2600,
      stopTimeoutMs: 240,

      // Exact constants visible in the video frame.
      baseInset: 8,
      strongerAttackerInsetPerLevel: 8, // raw video constant: gap * 4, then edm += edm
      strongerAttackerInsetCap: 24,     // avoid excessively late swings vs much smaller targets
      rawVideoLevelInsetEnabled: false, // true restores the uncapped screenshot-inspired behavior
      smallerAttackerInset: 10,
      bothAbove36Inset: 10,
      alignedFacingInsetMax: 5,
      angularMotionBonusPerDegree: 0.2,
      lowLevelBonusPivot: 42,
      lowLevelBonusPerLevel: 0.2,

      // Trigger compensation: earlier swing only while the center distance is closing.
      // The old d2 logic mostly changed aim direction; it did not pre-fire on approach.
      triggerLeadBaseMs: 42,
      triggerLeadPingScale: 0.5,
      triggerLeadMaxMs: 125,

      // The radial sum is an optimistic outer bound, not a guaranteed hit.
      // Smaller targets retain a small approach allowance; equal or larger
      // targets must penetrate the outer boundary before a swing is fired.
      contactInsetVsSmallerTarget: 16,
      contactInsetVsEqualTarget: 16,
      contactInsetVsLargerTarget: 18,
      closingLeadScaleVsSmallerTarget: 0.08,
      closingLeadScaleVsEqualTarget: 0.0,
      closingLeadScaleVsLargerTarget: 0.0,
      maxClosingLeadVsSmallerTarget: 10,
      maxClosingLeadVsEqualTarget: 0,
      maxClosingLeadVsLargerTarget: 0,

      // Hard upper bound for smaller targets. Positive prediction and angular
      // bonuses may improve timing, but they must never move the trigger back
      // to the optimistic outer-contact boundary where ghost flicks occur.
      smallerTargetGuaranteedPenetrationInset: 26,

      // Long one-sword forms magnify even a small optimistic ratio error.
      // Keep the exact engine reach, but require a few extra pixels of actual
      // penetration as the local weapon reach grows. This applies generally to
      // every smaller-target matchup rather than singling out levels 35 or 36.
      smallerTargetLongReachReference: 650,
      smallerTargetLongReachExtraInsetScale: 0.035,
      smallerTargetLongReachExtraInsetCap: 14
    };

    window._motionSnapshots = new Map();
    // Per-target trigger-zone frame counter. Each entry is
    //   { count: <consecutive in-range frames>, firstTime, lastTime }
    // The smart trigger uses this to require N consecutive frames of
    // in-range before firing, debouncing single-frame false positives.
    window._triggerFrames = new Map();

    // Updates a per-instance motion snapshot whenever the engine pushes
    // Updates a per-instance motion snapshot whenever the engine pushes
    // new sync data. The smart trigger reads these snapshots to project
    // target positions forward to contact time and to compute the radial
    // closing speed. Tunables live in window.visibleHeuristicTuning so
    // users can adjust them from the console.
    function updateSnapshotMotion(inst, now) {
      if (!inst || inst.uid === undefined) return;
      var uid = inst.uid;
      var previous = window._motionSnapshots.get(uid);
      if (!previous) {
        window._motionSnapshots.set(uid, {
          x: inst.x, y: inst.y, t: now, lastSeenT: now, vx: 0, vy: 0
        });
        return;
      }

      previous.lastSeenT = now;
      var dx = inst.x - previous.x;
      var dy = inst.y - previous.y;
      if ((Math.abs(dx) + Math.abs(dy)) < 0.001) {
        if ((now - previous.t) > window.visibleHeuristicTuning.stopTimeoutMs) {
          previous.vx = 0;
          previous.vy = 0;
        }
        return;
      }

      var dt = Math.max(0.001, (now - previous.t) / 1000);
      var rawVx = dx / dt;
      var rawVy = dy / dt;
      var rawSpeed = Math.hypot(rawVx, rawVy);
      var maxSpeed = window.visibleHeuristicTuning.maxTrackedSpeed;
      if (rawSpeed > maxSpeed && rawSpeed > 0) {
        var scale = maxSpeed / rawSpeed;
        rawVx *= scale;
        rawVy *= scale;
      }

      var alpha = window.visibleHeuristicTuning.velocityAlpha;
      previous.vx = previous.vx * (1 - alpha) + rawVx * alpha;
      previous.vy = previous.vy * (1 - alpha) + rawVy * alpha;
      previous.x = inst.x;
      previous.y = inst.y;
      previous.t = now;
    }

    // ======================================================
    // DYNAMIC INDEX OBJECT
    // Fallback values = confirmed hardcoded indices.
    // Scout overwrites these once runtime detection confirms them.
    // ======================================================
    window.dynamicIndices = { level: 10, boost: 16, angle: 15 };

    // ======================================================
    // SCOUT — heuristic runtime index detector
    // Observes myInst.instance_vars each tick to identify the
    // level, boost and angle indices without hardcoding.
    // Automatically deactivates once all three are confirmed.
    // ======================================================
    var scout = (function () {
        var _active = false;
        var _finished = false;
        var _confirmed = { level: false, boost: false, angle: false };
        var _prevVars = null;
        var _angleCandidates = {};   // idx → { count, last }
        var _boostCandidates = {};   // idx → toggle count
        var _levelCandidates = {};   // idx → confirmed increment count
        var _levelBlacklist  = {};   // idx → true (permanently disqualified)

        return {
            start: function () {
                if (_active || _finished) return;
                _active = true;
                console.log('[AutoHit Scout] Dynamic index detection started. Fallbacks active:', JSON.stringify(window.dynamicIndices));
            },

            tick: function (myInst) {
                if (!_active || !myInst || !myInst.instance_vars) return;
                var vars = myInst.instance_vars;
                var len = vars.length;
                if (len === 0) return;

                // ── ANGLE ────────────────────────────────────────────────
                if (!_confirmed.angle) {
                    for (var i = 0; i < len; i++) {
                        var v = vars[i];
                        if (typeof v === 'number' && !Number.isInteger(v) && v > -7.0 && v < 7.0) {
                            if (!_angleCandidates[i]) _angleCandidates[i] = { count: 0, last: v };
                            if (Math.abs(v - _angleCandidates[i].last) > 0.001) {
                                _angleCandidates[i].count++;
                                _angleCandidates[i].last = v;
                                if (_angleCandidates[i].count >= 15) {
                                    window.dynamicIndices.angle = i;
                                    INDEX_ANGLE_VAR = i;
                                    _confirmed.angle = true;
                                    console.log('[AutoHit Scout] Angle index confirmed:', i);
                                }
                            }
                        }
                    }
                }

                // ── FIRST-FRAME SNAPSHOT ─────────────────────────────────
                if (_prevVars === null) {
                    _prevVars = new Array(len);
                    for (var i = 0; i < len; i++) {
                        _prevVars[i] = vars[i];
                        var iv = vars[i];
                        if (typeof iv !== 'number' || iv % 1 !== 0 || iv < 0 || iv > 40) {
                            _levelBlacklist[i] = true;
                        }
                    }
                    return;
                }

                // ── LEVEL (ANTI-HIJACK PATCHED) ──────────────────────────
                if (!_confirmed.level) {
                    // Lekérjük a jelenleg megbízhatónak hitt index értékét ellenőrzésnek
                    var currentTrustedLevel = vars[window.dynamicIndices.level];

                    for (var i = 0; i < len; i++) {
                        if (_levelBlacklist[i]) continue;
                        var curr = vars[i], prev = _prevVars[i];

                        if (curr % 1 !== 0 || prev % 1 !== 0) {
                            _levelBlacklist[i] = true;
                            delete _levelCandidates[i];
                            continue;
                        }

                        if (curr < prev) {
                            _levelBlacklist[i] = true;
                            delete _levelCandidates[i];
                            continue;
                        }

                        if (curr - prev === 1 && curr >= 1 && curr <= 40) {
                            // TEAMS MÓD VÉDELEM: Ha a jelenlegi alapértelmezett index (10) egy reális,
                            // érvényes szintet mutat (pl. 17), akkor a vizsgált jelölt ÚJ értékének
                            // hajszálpontosan meg kell egyeznie ezzel. Ez megakadályozza, hogy az 0-ról induló
                            // kill/pont számlálók elcsalják a szintet, miközben mi a magas szinten várunk a szintlépésre.
                            if (typeof currentTrustedLevel === 'number' && currentTrustedLevel % 1 === 0 && currentTrustedLevel >= 0 && currentTrustedLevel <= 40) {
                                if (curr !== currentTrustedLevel) {
                                    continue; // Nem egyezik a valódi szinttel, ez egy hamis számláló (pl. Kills)!
                                }
                            }

                            if (!_levelCandidates[i]) _levelCandidates[i] = 0;
                            _levelCandidates[i]++;
                            if (_levelCandidates[i] >= 2) {
                                window.dynamicIndices.level = i;
                                _confirmed.level = true;
                                console.log('[AutoHit Scout] Level index confirmed:', i, '(value now ' + curr + ')');
                            }
                        }
                    }
                }

                // ── BOOST ────────────────────────────────────────────────
                if (!_confirmed.boost) {
                    for (var i = 0; i < len; i++) {
                        var curr = vars[i], prev = _prevVars[i];
                        if ((curr === 0 && prev === 1) || (curr === 1 && prev === 0)) {
                            if (!_boostCandidates[i]) _boostCandidates[i] = 0;
                            _boostCandidates[i]++;
                            if (_boostCandidates[i] >= 3) {
                                window.dynamicIndices.boost = i;
                                _confirmed.boost = true;
                                console.log('[AutoHit Scout] Boost index confirmed:', i);
                            }
                        }
                    }
                }

                // Update snapshot for next tick
                for (var i = 0; i < len; i++) _prevVars[i] = vars[i];

                // Deactivate once all three are locked in
                if (_confirmed.level && _confirmed.boost && _confirmed.angle) {
                    _active = false;
                    _finished = true;
                    console.log('[AutoHit Scout] All indices confirmed. Scout deactivated.',
                        JSON.stringify(window.dynamicIndices));
                }
            }
        };
    })();

    // Tap into the WS plugin tick to keep ping and wsWorker reference current
    var oldTick = powerWS.Instance.prototype.tick;
    powerWS.Instance.prototype.tick = function () {
      var measuredPing = Number(this.ping) || 0;
      window.ping = measuredPing;
      window.smoothedPing = window.smoothedPing === undefined
        ? measuredPing
        : window.smoothedPing * 0.85 + measuredPing * 0.15;
      wsWorker = this.wsWorker;
      isWSReady = this.isWSReady;
      oldTick.apply(this, arguments);
    };

    function endGame() {
      window.modData.inGame = false;
      window.modData.isAlive = false;
      window.closePlayerUIDS.clear();
      window.closestPlayerUID = undefined;
      // Reset the closest label back to its lobby indicator so the UI
      // stays consistent the moment we leave the match.
      if (closestPlayerLabel) closestPlayerLabel.textContent = "Sảnh chờ";
      if (typeof updateStatusDisplay === "function") updateStatusDisplay();
    }

    // ======================================================
    // LIVE WEAPON POLYGON REACH
    //
    // The visible weapon geometry is also the damaging geometry.
    // Prefer the live collision polygon exposed by the Construct 2 runtime.
    // Fall back to the weapon bounding quad, then to measured sprite widths.
    //
    // Internal animation ids are used directly (wpn_*_0). This avoids
    // display-level offset mistakes and also handles the double-sword forms.
    // wpn_3_0 was skipped by the logger after a two-level XP jump, so its
    // previously measured value is retained as a fallback.
    // ======================================================
    window.weaponReachFallbackByAnimation = {
      "wpn_0_0": 92.857544,
      "wpn_1_0": 116.071930,
      "wpn_2_0": 139.286316,
      "wpn_3_0": 135.000000,
      "wpn_4_0": 185.715088,
      "wpn_5_0": 208.929474,
      "wpn_6_0": 232.143860,
      "wpn_7_0": 255.358246,
      "wpn_8_0": 278.572632,
      "wpn_9_0": 301.787018,
      "wpn_10_0": 325.001404,
      "wpn_11_0": 348.215790,
      "wpn_12_0": 371.430176,
      "wpn_13_0": 394.644562,
      "wpn_14_0": 417.858948,
      "wpn_15_0": 441.073334,
      "wpn_16_0": 464.287720,
      "wpn_17_0": 487.502106,
      "wpn_18_0": 510.716492,
      "wpn_19_0": 533.930878,
      "wpn_20_0": 557.145264,
      "wpn_21_0": 580.359650,
      "wpn_22_0": 603.574036,
      "wpn_23_0": 626.788422,
      "wpn_24_0": 650.002808,
      "wpn_25_0": 673.217194,
      "wpn_26_0": 696.431580,
      "wpn_27_0": 719.645966,
      "wpn_28_0": 742.860352,
      "wpn_29_0": 766.074738,
      "wpn_30_0": 789.289124,
      "wpn_31_0": 812.503510,
      "wpn_32_0": 835.717896,
      "wpn_33_0": 858.932281,
      "wpn_34_0": 882.146667,
      "wpn_35_0": 905.361053,
      "wpn_36_0": 1086.433264,
      "wpn_37_0": 1086.433264,
      "wpn_38_0": 1086.433264,
      "wpn_39_0": 1086.433264,
      "wpn_40_0": 1146.790668
    };

    window.weaponReachTuning = {
      reachScale: 1.0,
      reachPadding: 0,
      associationTolerance: 8
    };

    // Runtime level 36 (the 37th displayed character) has one rear/decorative
    // polygon vertex farther from the player centre than the damaging visible
    // blade tip. Using the global maximum makes both the overlay and trigger
    // radius too large. The next outer polygon tip was measured directly.
    window.weaponReachOverrideByAnimation = {
      "wpn_36_0": 1063.130053
    };

    // Experimental per-animation vertex-rank selection.
    // Rank 1 = farthest collision-polygon vertex (default).
    // Rank 2 = second-farthest vertex. This is useful for weapons where the
    // outermost polygon vertex appears decorative or lies outside the active
    // damaging tip. Keep this switch reversible while A/B testing.
    window.weaponReachVertexRankTestEnabled = true;
    window.weaponReachVertexRankByAnimation = {
      "wpn_22_0": 2, // displayed character 23
      "wpn_24_0": 2, // displayed character 25
      "wpn_25_0": 2, // displayed character 26
      "wpn_29_0": 2, // displayed character 30
      "wpn_30_0": 2, // displayed character 31
      "wpn_32_0": 2  // displayed character 33
    };

    window.setSecondVertexReachTest = function (enabled) {
      window.weaponReachVertexRankTestEnabled = !!enabled;
      console.log(
        "[AutoHit] Second-vertex reach A/B test:",
        window.weaponReachVertexRankTestEnabled ? "ON" : "OFF"
      );
    };

    // Quick probe for the swing angle offset. Pass a number to apply it
    // immediately (or omit to just print the current effective value).
    // Iterate ±5° around the default until contacts land reliably.
    window.swingProbe = function (degrees) {
      if (!window.netTuning) window.netTuning = {};
      if (typeof degrees === "number" && !isNaN(degrees)) {
        window.netTuning.swingDegreesOverride = degrees;
      }
      var me = window.modData && window.modData.myInst;
      var level = me ? window.getLevelFromInst(me) : 0;
      var active = (window.getSwordForLevel || function (lv) {
        var s = window.swordLevelTable[lv] || { degrees: 130 };
        return s.degrees !== undefined ? s.degrees : 130;
      })(level);
      var effective = (window.netTuning.swingDegreesOverride !== null && window.netTuning.swingDegreesOverride !== undefined)
        ? window.netTuning.swingDegreesOverride
        : active + (window.netTuning.swingDegreesOffset || 0);
      console.log("[AutoHit] swingProbe — level", level,
        "table default", active + "°",
        "effective", effective + "°",
        "offset", (window.netTuning.swingDegreesOffset || 0) + "°",
        "override", (window.netTuning.swingDegreesOverride === null ? "null" : window.netTuning.swingDegreesOverride + "°"));
      return effective;
    };

    // Live autohit diagnostic. Call from the console to see exactly what the
    // trigger is computing for the closest enemy — distance, usable radius,
    // closing speed and the predicted target. Use this when autohit feels
    // off (too early, too late, or not firing) to confirm the values match
    // what the engine is reporting.
    window.autohitDiagnostic = function () {
      if (!window.modData || !window.modData.myInst) {
        console.log("[AutoHit] No local player yet.");
        return null;
      }
      var me = window.modData.myInst;
      var myLevel = window.getLevelFromInst(me);
      var now = performance.now();
      var myWeaponReachInfo = getWeaponReachForPlayer(me, myLevel);
      var myWeaponReach = myWeaponReachInfo.distance;
      var myCooldown = (window.cooldownTable && window.cooldownTable[myLevel]) || 200;
      var elapsed = now - (window.lastAutoHitTime || 0);
      var ready = elapsed > myCooldown;

      var players = getAllPlayerInstances();
      var closest = null;
      for (var i = 0; i < players.length; i++) {
        var p = players[i];
        if (!p || p === me) continue;
        var d = Math.sqrt((p.x - me.x) * (p.x - me.x) + (p.y - me.y) * (p.y - me.y));
        if (!closest || d < closest.distance) {
          var team = (p.instance_vars && p.instance_vars[36]);
          var isTeam = window.modData.gameMode === 1 && team === me.instance_vars[36];
          if (!isTeam) closest = { inst: p, distance: d, level: window.getLevelFromInst(p) };
        }
      }

      var report = {
        enabled: window.autoHitEnabled,
        myLevel: myLevel,
        myWeaponReach: Math.round(myWeaponReach),
        weaponReachSource: myWeaponReachInfo.source,
        cooldownMs: myCooldown,
        elapsedMs: Math.round(elapsed),
        ready: ready,
        predictedTargetUID: window.predictedTargetUID,
        currentTargetUID: window.currentTargetUID
      };

      if (closest) {
        var levelDiffForDiag = myLevel - closest.level;
        var bodyRadiusBonusForDiag = levelDiffForDiag > 0
          ? Math.min(
              window.netTuning.smallerTargetBodyBonusCap || 12,
              levelDiffForDiag * (window.netTuning.smallerTargetBodyBonusPerLevel || 1.5)
            )
          : 0;
        var bodyR = calculateTargetRadius(closest.level) * window.netTuning.targetRadiusScale
          + (window.netTuning.targetRadiusPadding || 0)
          + bodyRadiusBonusForDiag;
        var totalR = myWeaponReach + bodyR;

        // Closing speed
        var closing = 0;
        if (window._motionSnapshots) {
          var myS = window._motionSnapshots.get(me.uid);
          var tgS = window._motionSnapshots.get(closest.inst.uid);
          if (myS && tgS) {
            var rdx = (tgS.vx || 0) - (myS.vx || 0);
            var rdy = (tgS.vy || 0) - (myS.vy || 0);
            if (closest.distance > 0) {
              closing = Math.max(0, -((closest.inst.x - me.x) * rdx + (closest.inst.y - me.y) * rdy) / closest.distance);
            }
          }
        }
        var baseInsetForDiag = (window.netTuning.currentDistanceInset || 0);
        var reachScaleForDiag = 1;
        if (window.netTuning.reachAwarePrefire) {
          var refReachD = window.netTuning.reachPrefireReference || 250;
          var minReachD = window.netTuning.reachPrefireMin || 50;
          reachScaleForDiag = myWeaponReach < refReachD
            ? refReachD / Math.max(minReachD, myWeaponReach)
            : 1;
        }
        var scaledInsetForDiag = baseInsetForDiag * reachScaleForDiag;
        var pingMsForDiag = Number(window.smoothedPing || window.ping || 0);
        var preFireMsForDiag = Math.min(
          window.netTuning.preFireMaxMs || 120,
          (window.netTuning.preFireBaseMs || 35) + pingMsForDiag * (window.netTuning.preFirePingScale || 0.5)
        );
        var closingLeadForDiag = Math.min(
          window.netTuning.closingLeadCap || 40,
          closing * (preFireMsForDiag / 1000) * (window.netTuning.closingLeadScale || 0.5)
        );
        var dynamicInset = scaledInsetForDiag - closingLeadForDiag;
        var usable = Math.max(1, totalR - dynamicInset);

        report.closest = {
          uid: closest.inst.uid,
          name: closest.inst.instance_vars && closest.inst.instance_vars[18],
          level: closest.level,
          distance: Math.round(closest.distance),
          bodyRadius: Math.round(bodyR),
          totalRadius: Math.round(totalR),
          closingSpeedPxPerSec: Math.round(closing),
          reachScale: Math.round(reachScaleForDiag * 100) / 100,
          bodyRadiusBonus: Math.round(bodyRadiusBonusForDiag * 10) / 10,
          dynamicInset: Math.round(dynamicInset * 10) / 10,
          usableRadius: Math.round(usable),
          wouldFire: ready && closest.distance <= usable,
          deltaPx: Math.round((closest.distance - usable) * 10) / 10
        };
      } else {
        report.closest = null;
      }

      console.table([{
        enabled: report.enabled,
        myLevel: report.myLevel,
        cooldownMs: report.cooldownMs,
        ready: report.ready,
        closestName: report.closest ? report.closest.name : "—",
        closestLevel: report.closest ? report.closest.level : "—",
        distance: report.closest ? report.closest.distance : "—",
        totalRadius: report.closest ? report.closest.totalRadius : "—",
        reachScale: report.closest ? report.closest.reachScale : "—",
        bodyRadiusBonus: report.closest ? report.closest.bodyRadiusBonus : "—",
        closingSpeed: report.closest ? report.closest.closingSpeedPxPerSec : "—",
        dynamicInset: report.closest ? report.closest.dynamicInset : "—",
        usableRadius: report.closest ? report.closest.usableRadius : "—",
        deltaPx: report.closest ? report.closest.deltaPx : "—",
        wouldFire: report.closest ? report.closest.wouldFire : "—"
      }]);
      return report;
    };

    function getWeaponAnimationName(weaponInst) {
      return weaponInst && weaponInst.cur_animation
        ? (weaponInst.cur_animation.name || "")
        : "";
    }

    function isWeaponInstance(inst) {
      return !!inst && getWeaponAnimationName(inst).indexOf("wpn_") === 0;
    }

    function findWeaponInstanceForPlayer(playerInst) {
      var rt = window.runtime;
      if (!playerInst || !rt || !rt.types_by_index) return null;

      var best = null;
      var bestDistance = Infinity;

      for (var i = 0; i < rt.types_by_index.length; i++) {
        var type = rt.types_by_index[i];
        if (!type || !type.instances) continue;

        // t259 is the observed weapon type. The animation check remains as a
        // fallback in case the minified runtime changes its generated name.
        var isObservedWeaponType = type.name === "t259";

        for (var j = 0; j < type.instances.length; j++) {
          var inst = type.instances[j];
          if (!inst || (!isObservedWeaponType && !isWeaponInstance(inst))) continue;
          if (!isWeaponInstance(inst)) continue;

          var dx = (Number(inst.x) || 0) - (Number(playerInst.x) || 0);
          var dy = (Number(inst.y) || 0) - (Number(playerInst.y) || 0);
          var distance = Math.sqrt(dx * dx + dy * dy);

          if (distance < bestDistance) {
            best = inst;
            bestDistance = distance;
          }
        }
      }

      return bestDistance <= window.weaponReachTuning.associationTolerance
        ? best
        : null;
    }

    function extractCollisionPolygonWorldPoints(weaponInst) {
      if (!weaponInst) return [];

      var poly = weaponInst.collision_poly;
      if (!poly) return [];

      try {
        if (typeof poly.cache_poly === "function") {
          poly.cache_poly(weaponInst.width, weaponInst.height, weaponInst.angle);
        }
      } catch (_) {}

      var cached = poly.pts_cache;
      if (!cached || cached.length < 4) return [];

      var localPoints = [];

      if (typeof cached[0] === "number") {
        for (var i = 0; i + 1 < cached.length; i += 2) {
          var x = Number(cached[i]);
          var y = Number(cached[i + 1]);
          if (Number.isFinite(x) && Number.isFinite(y)) {
            localPoints.push({ x: x, y: y });
          }
        }
      } else {
        for (var j = 0; j < cached.length; j++) {
          var point = cached[j];
          if (!point) continue;
          var px = Number(point.x);
          var py = Number(point.y);
          if (Number.isFinite(px) && Number.isFinite(py)) {
            localPoints.push({ x: px, y: py });
          }
        }
      }

      if (localPoints.length < 2) return [];

      // In Construct 2 pts_cache is normally relative to the instance origin.
      // The plausibility check also supports absolute coordinates if a runtime
      // build exposes them in world space.
      var wx = Number(weaponInst.x) || 0;
      var wy = Number(weaponInst.y) || 0;
      var dimension = Math.max(
        Math.abs(Number(weaponInst.width) || 0),
        Math.abs(Number(weaponInst.height) || 0),
        1
      );

      var maxAbsCoordinate = 0;
      for (var k = 0; k < localPoints.length; k++) {
        maxAbsCoordinate = Math.max(
          maxAbsCoordinate,
          Math.abs(localPoints[k].x),
          Math.abs(localPoints[k].y)
        );
      }

      var pointsAreLocal = maxAbsCoordinate <= dimension * 3 + 100;
      var worldPoints = [];

      for (var n = 0; n < localPoints.length; n++) {
        worldPoints.push(pointsAreLocal
          ? { x: wx + localPoints[n].x, y: wy + localPoints[n].y }
          : { x: localPoints[n].x, y: localPoints[n].y });
      }

      return worldPoints;
    }

    function extractBoundingQuadWorldPoints(weaponInst) {
      if (!weaponInst) return [];

      try {
        if (typeof weaponInst.update_bbox === "function") weaponInst.update_bbox();
      } catch (_) {}

      var quad = weaponInst.bquad;
      if (!quad) return [];

      var tryValue = quad.try_ !== undefined ? quad.try_ : quad["try"];
      var points = [
        { x: Number(quad.tlx), y: Number(quad.tly) },
        { x: Number(quad.trx), y: Number(tryValue) },
        { x: Number(quad.brx), y: Number(quad.bry) },
        { x: Number(quad.blx), y: Number(quad.bly) }
      ];

      return points.filter(function (point) {
        return Number.isFinite(point.x) && Number.isFinite(point.y);
      });
    }

    function rankedDistanceFromPlayerCenter(playerInst, points, rank) {
      if (!playerInst || !points || points.length === 0) return null;

      var distances = [];

      for (var i = 0; i < points.length; i++) {
        var dx = points[i].x - playerInst.x;
        var dy = points[i].y - playerInst.y;
        var distance = Math.sqrt(dx * dx + dy * dy);

        if (Number.isFinite(distance) && distance > 0) {
          distances.push(distance);
        }
      }

      if (distances.length === 0) return null;

      distances.sort(function (a, b) {
        return b - a;
      });

      var requestedRank = Math.max(1, Number(rank) || 1);
      var selectedIndex = Math.min(distances.length - 1, requestedRank - 1);
      var selectedDistance = distances[selectedIndex];

      return Number.isFinite(selectedDistance) && selectedDistance > 0
        ? selectedDistance
        : null;
    }

    function getConfiguredReachVertexRank(animationName) {
      if (!window.weaponReachVertexRankTestEnabled) return 1;

      var configured =
        window.weaponReachVertexRankByAnimation[animationName];

      return Number.isFinite(configured)
        ? Math.max(1, configured)
        : 1;
    }

    function getFallbackWeaponReach(level, animationName) {
      var name = animationName || ("wpn_" + level + "_0");
      var measured = window.weaponReachFallbackByAnimation[name];

      if (Number.isFinite(measured)) return measured;

      var legacy = window.swordLevelTable[level];
      return legacy && Number.isFinite(legacy.distance)
        ? legacy.distance
        : 200;
    }

    function getWeaponReachForPlayer(playerInst, level) {
      var weaponInst = findWeaponInstanceForPlayer(playerInst);
      var animationName = getWeaponAnimationName(weaponInst);
      var points = extractCollisionPolygonWorldPoints(weaponInst);
      var source = "collision-poly";

      if (points.length === 0) {
        points = extractBoundingQuadWorldPoints(weaponInst);
        source = "bquad";
      }

      var configuredReachVertexRank = getConfiguredReachVertexRank(animationName);
      // Keep the configured engine-derived weapon reach. Do not automatically
      // discard isolated outer polygon points: for many weapons the protruding
      // blade tip is the real damaging endpoint.
      var reachVertexRank = configuredReachVertexRank;
      var liveReach = rankedDistanceFromPlayerCenter(
        playerInst,
        points,
        reachVertexRank
      );
      var fallbackReach = getFallbackWeaponReach(level, animationName);
      var overrideReach = window.weaponReachOverrideByAnimation[animationName];
      var hasOverride = Number.isFinite(overrideReach);
      var rawReach = hasOverride
        ? overrideReach
        : (liveReach !== null ? liveReach : fallbackReach);

      return {
        distance: rawReach * window.weaponReachTuning.reachScale
          + window.weaponReachTuning.reachPadding,
        rawDistance: rawReach,
        source: hasOverride
          ? "collision-poly-override"
          : (liveReach !== null
              ? source + "-rank-" + reachVertexRank
              : "fallback-table"),
        animation: animationName || ("wpn_" + level + "_0"),
        weaponInst: weaponInst,
        pointCount: points.length,
        reachVertexRank: reachVertexRank,
        configuredReachVertexRank: configuredReachVertexRank
      };
    }

    function getSword(level) {
      var legacy = window.swordLevelTable[level] || { degrees: 130 };
      var defaultDegrees = legacy.degrees !== undefined ? legacy.degrees : 130;
      var tuning = window.netTuning || {};
      // If swingDegreesOverride is set and not null, use it for every level.
      // Otherwise apply the optional offset on top of the per-character
      // default. This lets the user retune the swing angle from the console
      // without editing the static table.
      var degrees = tuning.swingDegreesOverride !== undefined && tuning.swingDegreesOverride !== null
        ? Number(tuning.swingDegreesOverride)
        : defaultDegrees + (Number(tuning.swingDegreesOffset) || 0);
      return {
        distance: getFallbackWeaponReach(level),
        degrees: degrees
      };
    }

    // Manual diagnostics. These only print when explicitly called.
    window.inspectSwordGeometry = function () {
      var me = window.modData && window.modData.myInst;
      if (!me) return null;

      var level = window.getLevelFromInst(me);
      var reach = getWeaponReachForPlayer(me, level);
      var weapon = reach.weaponInst;
      var result = {
        internalLevel: level,
        animation: reach.animation,
        source: reach.source,
        damagingReach: reach.distance,
        polygonPointCount: reach.pointCount,
        reachVertexRank: reach.reachVertexRank,
        configuredReachVertexRank: reach.configuredReachVertexRank,
        spriteWidth: weapon ? Math.abs(Number(weapon.width) || 0) : null,
        spriteHeight: weapon ? Math.abs(Number(weapon.height) || 0) : null,
        hotspotX: weapon ? weapon.hotspotX : null,
        hotspotY: weapon ? weapon.hotspotY : null
      };

      console.table([result]);
      return result;
    };

    window.inspectWeaponReachCandidates = function () {
      var me = window.modData && window.modData.myInst;
      if (!me) return null;

      var level = window.getLevelFromInst(me);
      var weaponInst = findWeaponInstanceForPlayer(me);
      var animationName = getWeaponAnimationName(weaponInst);
      var points = extractCollisionPolygonWorldPoints(weaponInst);

      if (points.length === 0) {
        points = extractBoundingQuadWorldPoints(weaponInst);
      }

      var rows = [];

      for (var i = 0; i < points.length; i++) {
        var dx = points[i].x - me.x;
        var dy = points[i].y - me.y;
        rows.push({
          pointIndex: i,
          distanceFromPlayer: Math.sqrt(dx * dx + dy * dy),
          worldX: points[i].x,
          worldY: points[i].y
        });
      }

      rows.sort(function (a, b) {
        return b.distanceFromPlayer - a.distanceFromPlayer;
      });

      var configuredRank = getConfiguredReachVertexRank(animationName);

      for (var j = 0; j < rows.length; j++) {
        rows[j].distanceRank = j + 1;
        rows[j].selectedByCurrentConfig = (j + 1) === configuredRank;
      }

      console.log({
        internalLevel: level,
        displayedCharacterNumber: Number(level) + 1,
        animation: animationName,
        configuredReachVertexRank: configuredRank,
        secondVertexTestEnabled: window.weaponReachVertexRankTestEnabled
      });
      console.table(rows);
      return rows;
    };

    // Clamps the line from (myCx, myCy) toward (cx, cy) to the inside edge
    // of the screen rect, leaving a configurable margin from each side.
    // Returns the indicator position and the angle toward the off-screen
    // target so the caller can rotate a triangle arrow accordingly.
    function projectToScreenEdge(myCx, myCy, cx, cy, margin) {
      var screenW = window.innerWidth;
      var screenH = window.innerHeight;
      var dx = cx - myCx;
      var dy = cy - myCy;

      if (dx === 0 && dy === 0) {
        return { x: myCx, y: myCy, angle: 0 };
      }

      // Find t for each edge (positive = forward direction from myCx/myCy)
      var bestT = Infinity;
      if (dx !== 0) {
        var tL = (margin - myCx) / dx;
        var tR = (screenW - margin - myCx) / dx;
        if (tL > 0 && tL < bestT) bestT = tL;
        if (tR > 0 && tR < bestT) bestT = tR;
      }
      if (dy !== 0) {
        var tT = (margin - myCy) / dy;
        var tB = (screenH - margin - myCy) / dy;
        if (tT > 0 && tT < bestT) bestT = tT;
        if (tB > 0 && tB < bestT) bestT = tB;
      }

      if (!Number.isFinite(bestT) || bestT === Infinity) {
        // Fallback: clamp to screen rect so the indicator stays visible.
        return {
          x: Math.max(margin, Math.min(screenW - margin, cx)),
          y: Math.max(margin, Math.min(screenH - margin, cy)),
          angle: Math.atan2(dy, dx)
        };
      }

      return {
        x: myCx + dx * bestT,
        y: myCy + dy * bestT,
        angle: Math.atan2(dy, dx)
      };
    }

    // Draws an off-screen indicator at the screen edge: a triangle arrow
    // pointing toward the target, an optional line extending from the
    // arrow toward the target direction, and a label with name/level/
    // distance. Color follows the same priority as the in-view ESP.
    function drawOffscreenIndicator(ctx, myCx, myCy, cx, cy, playerInst, enemyLevel, distance, flags, settings) {
      var color;
      if (flags.isCurrentTarget) {
        color = settings.offscreenIndicatorCurrentTargetColor;
      } else if (flags.isEligibleBigTarget) {
        color = settings.offscreenIndicatorEligibleBigTargetColor;
      } else if (flags.isTeammate) {
        color = settings.offscreenIndicatorTeammateColor;
      } else {
        color = settings.offscreenIndicatorEnemyColor;
      }
      if (flags.isIneligibleBigTarget && settings.bigTargetHighlight === "dim") {
        ctx.globalAlpha = settings.bigTargetIneligibleAlpha;
      }

      var margin = settings.offscreenIndicatorMargin || 40;
      var edge = projectToScreenEdge(myCx, myCy, cx, cy, margin);
      var size = settings.offscreenIndicatorSize || 10;
      var dx = cx - edge.x;
      var dy = cy - edge.y;

      // Optional guide line from the screen edge toward the target.
      if (settings.offscreenIndicatorShowLine) {
        var lineLen = settings.offscreenIndicatorLineLength || 60;
        var nx = dx, ny = dy;
        var nLen = Math.hypot(nx, ny);
        if (nLen > 0) {
          nx /= nLen; ny /= nLen;
        }
        var lineEndX = edge.x + nx * lineLen;
        var lineEndY = edge.y + ny * lineLen;
        ctx.beginPath();
        ctx.moveTo(edge.x, edge.y);
        ctx.lineTo(lineEndX, lineEndY);
        ctx.strokeStyle = color;
        ctx.lineWidth = 1.5;
        ctx.lineCap = "round";
        ctx.stroke();
      }

      // Triangle arrow at the edge, tip pointing toward the target.
      if (settings.offscreenIndicatorShowArrow) {
        ctx.save();
        ctx.translate(edge.x, edge.y);
        ctx.rotate(edge.angle);
        ctx.beginPath();
        ctx.moveTo(size, 0);
        ctx.lineTo(-size * 0.6, -size * 0.6);
        ctx.lineTo(-size * 0.6, size * 0.6);
        ctx.closePath();
        ctx.fillStyle = color;
        ctx.fill();
        ctx.strokeStyle = "rgba(0,0,0,0.7)";
        ctx.lineWidth = 1;
        ctx.stroke();
        ctx.restore();
      }

      // Label: name [L<level>] <distance>px, truncated like the in-view ESP.
      var label = "";
      if (settings.offscreenIndicatorShowName) {
        var name = playerInst.instance_vars && playerInst.instance_vars[18];
        if (typeof name === 'string') label = name;
        else if (name !== undefined && name !== null) label = String(name);
        if (label.length > 14) label = label.substring(0, 14) + "…";
      }
      if (settings.offscreenIndicatorShowLevel) {
        label += (label ? " " : "") + "[L" + (enemyLevel + 1) + "]";
      }
      if (settings.offscreenIndicatorShowDistance) {
        label += (label ? " " : "") + Math.round(distance) + "px";
      }
      // Append level diff to the off-screen label so the user knows at a
      // glance whether the off-screen target is a threat. "+N" = higher,
      // "-N" = lower, "=" = same level. Matches the in-view pill style.
      if (settings.showLevelDiff) {
        var myLvlOff = window.modData && window.modData.myInst
          ? (window.getLevelFromInst && window.getLevelFromInst(window.modData.myInst)) || 0
          : 0;
        var lvlDiffOff = enemyLevel - myLvlOff;
        var diffStrOff = lvlDiffOff > 0 ? "+" + lvlDiffOff
          : (lvlDiffOff < 0 ? String(lvlDiffOff) : "=");
        label += (label ? " " : "") + "[" + diffStrOff + "]";
      }

      if (!label) {
        if (ctx.globalAlpha !== 1) ctx.globalAlpha = 1;
        return;
      }

      // Place the label in the direction AWAY from the target so it
      // sits on the screen side opposite to the off-screen target.
      var arrowLen = settings.offscreenIndicatorArrowLength || 32;
      var textOffsetX = -Math.cos(edge.angle) * (size + arrowLen);
      var textOffsetY = -Math.sin(edge.angle) * (size + arrowLen);
      var textX = edge.x + textOffsetX;
      var textY = edge.y + textOffsetY;

      // Keep the label inside the screen rect (clamp with a small pad).
      var pad = 4;
      if (textX < margin) {
        textX = margin + pad;
        ctx.textAlign = "left";
      } else if (textX > window.innerWidth - margin) {
        textX = window.innerWidth - margin - pad;
        ctx.textAlign = "right";
      } else {
        ctx.textAlign = "center";
      }
      if (textY < margin) textY = margin + pad;
      if (textY > window.innerHeight - margin) textY = window.innerHeight - margin - pad;
      ctx.textBaseline = "middle";

      var fontSize = Math.max(10, settings.offscreenIndicatorFontSize || 12);
      ctx.font = "bold " + fontSize + "px Lucida Sans Unicode, monospace";
      ctx.fillStyle = settings.offscreenIndicatorShadow || "rgba(0,0,0,0.85)";
      ctx.fillText(label, textX + 1, textY + 1);
      ctx.fillStyle = color;
      ctx.fillText(label, textX, textY);

      // Add a small "OFF" tag in front of the current target so the user
      // knows to look at the screen edge to find the bot's intended victim.
      if (flags.isCurrentTarget) {
        var tagText = "▶";
        var tagFontSize = Math.max(10, fontSize + 1);
        ctx.font = "bold " + tagFontSize + "px Lucida Sans Unicode, monospace";
        ctx.textAlign = "center";
        ctx.textBaseline = "middle";
        var tagX = edge.x + Math.cos(edge.angle) * (size + 8);
        var tagY = edge.y + Math.sin(edge.angle) * (size + 8);
        ctx.fillStyle = settings.offscreenIndicatorShadow || "rgba(0,0,0,0.85)";
        ctx.fillText(tagText, tagX + 1, tagY + 1);
        ctx.fillStyle = color;
        ctx.fillText(tagText, tagX, tagY);
      }

      if (ctx.globalAlpha !== 1) ctx.globalAlpha = 1;
    }

    // Creates a transparent overlay canvas on top of the game canvas
    function setupOverlayCanvas() {
        if (window.autohitOverlay) return;
        var overlay = document.createElement('canvas');
        overlay.id = 'autohit-range-overlay';
        // width/height 100% fills the viewport automatically in fullscreen too
        overlay.style.cssText = 'position:fixed;top:0;left:0;width:100%;height:100%;pointer-events:none;z-index:9998;';
        document.body.appendChild(overlay);
        window.autohitOverlay = overlay;
        window.autohitOverlayCtx = overlay.getContext('2d');
    }

    // Returns every live player instance currently registered in the runtime.
    // Player type is identified by its 72-instance-var signature, which is how
    // the local-player fallback in AllLoop() also recognises it.
    function getAllPlayerInstances() {
      var rt = window.runtime;
      if (!rt || !rt.types_by_index) return [];
      for (var i = 0; i < rt.types_by_index.length; i++) {
        var t = rt.types_by_index[i];
        if (t && t.instvar_sids && t.instvar_sids.length === 72 && t.instances) {
          return t.instances;
        }
      }
      return [];
    }

    // Draws the through-wall ESP overlay: corner brackets, nickname, internal
    // level, live distance, snapline and a small HP bar (when available). All
    // values are read directly from the C2 instance vars, so the overlay
    // reflects the live engine state without any prediction.
    function drawEspOverlay(ctx, layer, scaleX, scaleY, bounds) {
      var myInst = window.modData && window.modData.myInst;
      if (!myInst) return;
      var myUid = myInst.uid;
      var myTeam = myInst.instance_vars && myInst.instance_vars[36];
      var myLevel = window.getLevelFromInst(myInst) || 0;
      var settings = window.espSettings;
      if (!settings) return;

      var players = getAllPlayerInstances();
      if (!players.length) return;

      var isTeamMode = window.modData.gameMode === 1;
      var bigTargetActive = !!window.bigCharacterMode;
      var bigTargetThreshold = myLevel - 5;
      var myCx = bounds.left + (myInst.x - layer.viewLeft) * scaleX;
      var myCy = bounds.top  + (myInst.y - layer.viewTop)  * scaleY;
      var fontSize = Math.max(10, settings.fontSize * Math.min(scaleX, scaleY));
      var cornerLen = Math.max(6, settings.cornerLength * Math.min(scaleX, scaleY));

      for (var i = 0; i < players.length; i++) {
        var p = players[i];
        if (!p || p === myInst || p.uid === myUid) continue;

        var dx = p.x - myInst.x;
        var dy = p.y - myInst.y;
        var distance = Math.sqrt(dx * dx + dy * dy);
        if (distance < 1 || distance > settings.maxDistance) {
          // Never cull the autohit's current target — the highlight must stay
          // visible while the bot is tracking it, even from across the map.
          var isCurrentForCull = settings.highlightCurrentTarget
            && window.autoHitEnabled
            && p.uid === window.predictedTargetUID;
          if (!(isCurrentForCull && settings.alwaysShowCurrentTarget)) continue;
        }

        var enemyLevel = window.getLevelFromInst(p) || 0;
        var enemyTeam = p.instance_vars && p.instance_vars[36];
        var isTeammate = isTeamMode && (myTeam === enemyTeam);
        if (isTeammate && !settings.showTeammates) continue;

        // Target classifications (priority order):
        // 1. predictedTargetUID — the next enemy the bot will swing at
        //    (recomputed every frame, so the highlight is visible from the
        //    moment a valid target enters range, not only after the swing
        //    fires — matches the always-on name/box rendering).
        // 2. eligible big target — within 5 levels of the local player
        // 3. ineligible big target — outside that range while big target is on
        var isCurrentTarget = settings.highlightCurrentTarget
          && window.autoHitEnabled
          && p.uid === window.predictedTargetUID;
        var isEligibleBigTarget = bigTargetActive && enemyLevel >= bigTargetThreshold;
        var isIneligibleBigTarget = bigTargetActive && enemyLevel < bigTargetThreshold;

        if (settings.bigTargetHighlight === "hide" && isIneligibleBigTarget) {
          continue;
        }

        var spriteW = Math.abs(Number(p.width) || 0);
        var spriteH = Math.abs(Number(p.height) || 0);
        if (spriteW === 0) spriteW = calculateTargetRadius(enemyLevel) * 2.6;
        if (spriteH === 0) spriteH = calculateTargetRadius(enemyLevel) * 2.6;

        var cx = bounds.left + (p.x - layer.viewLeft) * scaleX;
        var cy = bounds.top  + (p.y - layer.viewTop)  * scaleY;
        var halfW = (spriteW * scaleX) / 2;
        var halfH = (spriteH * scaleY) / 2;
        var left = cx - halfW, right = cx + halfW;
        var top = cy - halfH, bottom = cy + halfH;

        // Off-screen detection. The in-view box only makes sense when the
        // sprite is on screen, so we replace it with a screen-edge arrow
        // for players outside the camera view. Classification info still
        // comes through (current target, eligible big target, etc.).
        var isOffscreen = p.x < layer.viewLeft
          || p.x > layer.viewRight
          || p.y < layer.viewTop
          || p.y > layer.viewBottom;
        if (isOffscreen && settings.showOffscreenIndicators) {
          drawOffscreenIndicator(ctx, myCx, myCy, cx, cy, p, enemyLevel, distance, {
            isCurrentTarget: isCurrentTarget,
            isTeammate: isTeammate,
            isEligibleBigTarget: isEligibleBigTarget,
            isIneligibleBigTarget: isIneligibleBigTarget
          }, settings);
          continue;
        }

        // Box colour priority: current target > eligible big target > team/enemy.
        var boxColor;
        if (isCurrentTarget) {
          boxColor = settings.currentTargetBoxColor;
        } else if (isEligibleBigTarget) {
          boxColor = settings.bigTargetEligibleColor;
        } else if (isTeammate) {
          boxColor = settings.teammateBoxColor;
        } else {
          boxColor = settings.enemyBoxColor;
        }

        // Dim ineligible targets so the eligible ones stand out.
        if (isIneligibleBigTarget && settings.bigTargetHighlight === "dim") {
          ctx.globalAlpha = settings.bigTargetIneligibleAlpha;
        }

        // Snapline from the local player to the target.
        if (settings.showSnaplines) {
          // Outer glow for the current target — wide, semi-transparent halo
          // that makes the bold yellow line stand out against the rest.
          if (isCurrentTarget) {
            ctx.beginPath();
            ctx.moveTo(myCx, myCy);
            ctx.lineTo(cx, cy);
            ctx.strokeStyle = settings.currentTargetGlowColor || "rgba(255, 235, 59, 0.3)";
            ctx.lineWidth = settings.currentTargetGlowWidth || (settings.currentTargetSnaplineWidth * 2.5);
            ctx.lineCap = "round";
            ctx.stroke();
          }

          ctx.beginPath();
          ctx.moveTo(myCx, myCy);
          ctx.lineTo(cx, cy);
          if (isCurrentTarget) {
            ctx.strokeStyle = settings.currentTargetSnaplineColor;
            ctx.lineWidth = settings.currentTargetSnaplineWidth;
            ctx.lineCap = "round";
          } else if (isEligibleBigTarget) {
            ctx.strokeStyle = settings.bigTargetSnaplineEligibleColor;
            ctx.lineWidth = 1.5;
            ctx.lineCap = "round";
          } else {
            ctx.strokeStyle = isTeammate
              ? settings.snaplineTeammateColor
              : settings.snaplineEnemyColor;
            ctx.lineWidth = 1;
          }
          ctx.stroke();
        }

        // Corner-bracket box: only the four L-shapes are drawn so the player's
        // own sprite stays readable underneath.
        if (settings.showBoxes) {
          ctx.strokeStyle = boxColor;
          ctx.lineWidth = isCurrentTarget
            ? settings.boxThickness * (settings.currentTargetBoxThicknessMultiplier || 2.8)
            : settings.boxThickness;
          // top-left
          ctx.beginPath();
          ctx.moveTo(left, top + cornerLen); ctx.lineTo(left, top); ctx.lineTo(left + cornerLen, top);
          // top-right
          ctx.beginPath();
          ctx.moveTo(right - cornerLen, top); ctx.lineTo(right, top); ctx.lineTo(right, top + cornerLen);
          // bottom-right
          ctx.beginPath();
          ctx.moveTo(right, bottom - cornerLen); ctx.lineTo(right, bottom); ctx.lineTo(right - cornerLen, bottom);
          // bottom-left
          ctx.beginPath();
          ctx.moveTo(left + cornerLen, bottom); ctx.lineTo(left, bottom); ctx.lineTo(left, bottom - cornerLen);
          ctx.stroke();
        }

        // Level badge — a small filled square in the top-left of the box
        // showing the displayed character number (level + 1). Easier to
        // spot at a glance than parsing [L21] in the nickname line.
        if (settings.showLevelBadge && settings.showBoxes) {
          var badgeSize = Math.max(14, (settings.levelBadgeSize || 22) * Math.min(scaleX, scaleY));
          var badgeX = left - badgeSize * 0.15;
          var badgeY = top - badgeSize * 0.15;
          var badgeFontSize = Math.max(9, (settings.levelBadgeFontSize || 12) * Math.min(scaleX, scaleY));
          // Badge background uses the same priority as the box border so
          // a cyan current target still reads as "current target".
          ctx.fillStyle = boxColor;
          ctx.fillRect(badgeX, badgeY, badgeSize, badgeSize);
          ctx.strokeStyle = "rgba(0, 0, 0, 0.85)";
          ctx.lineWidth = 1;
          ctx.strokeRect(badgeX, badgeY, badgeSize, badgeSize);
          // Number text.
          ctx.font = "bold " + Math.round(badgeFontSize) + "px Lucida Sans Unicode, monospace";
          ctx.textAlign = "center";
          ctx.textBaseline = "middle";
          ctx.fillStyle = settings.levelBadgeShadow || "rgba(0, 0, 0, 0.85)";
          ctx.fillText(String(enemyLevel + 1), badgeX + badgeSize / 2 + 1, badgeY + badgeSize / 2 + 1);
          ctx.fillStyle = settings.levelBadgeTextColor || "#ffffff";
          ctx.fillText(String(enemyLevel + 1), badgeX + badgeSize / 2, badgeY + badgeSize / 2);
          // Restore the nickname font so subsequent text in this loop
          // iteration renders at the default size.
          ctx.font = "bold " + fontSize + "px Lucida Sans Unicode, monospace";
        }

        // Level diff — "+N" or "-N" relative to the local player, drawn
        // in the top-right of the box. Colour is threat-coded so a tough
        // matchup is obvious before contact.
        if (settings.showLevelDiff && settings.showBoxes) {
          var myLvlForDiff = window.modData && window.modData.myInst
            ? (window.getLevelFromInst && window.getLevelFromInst(window.modData.myInst)) || 0
            : 0;
          var lvlDiff = enemyLevel - myLvlForDiff;
          var diffStr = lvlDiff > 0 ? "+" + lvlDiff
            : (lvlDiff < 0 ? String(lvlDiff) : "=");
          var diffDanger = settings.levelDiffDangerThreshold || 5;
          var diffColor;
          if (lvlDiff >= diffDanger) {
            diffColor = settings.levelDiffDangerColor;
          } else if (lvlDiff > 0) {
            diffColor = settings.levelDiffHigherColor;
          } else if (lvlDiff === 0) {
            diffColor = settings.levelDiffEqualColor;
          } else {
            diffColor = settings.levelDiffLowerColor;
          }
          var diffFontSize = Math.max(10, (settings.levelDiffFontSize || 12) * Math.min(scaleX, scaleY));
          ctx.font = "bold " + Math.round(diffFontSize) + "px Lucida Sans Unicode, monospace";
          ctx.textAlign = "center";
          ctx.textBaseline = "middle";
          // Background pill so the tag stays readable on any sprite.
          var pillW = Math.round(diffFontSize * (diffStr.length * 0.7 + 1.2));
          var pillH = Math.round(diffFontSize * 1.3);
          var pillX = right - pillW * 0.85;
          var pillY = top - pillH * 0.15;
          ctx.fillStyle = "rgba(0, 0, 0, 0.7)";
          ctx.fillRect(pillX, pillY, pillW, pillH);
          ctx.strokeStyle = diffColor;
          ctx.lineWidth = 1.5;
          ctx.strokeRect(pillX, pillY, pillW, pillH);
          // Text.
          ctx.fillStyle = "rgba(0, 0, 0, 0.85)";
          ctx.fillText(diffStr, pillX + pillW / 2 + 1, pillY + pillH / 2 + 1);
          ctx.fillStyle = diffColor;
          ctx.fillText(diffStr, pillX + pillW / 2, pillY + pillH / 2);
          // Reset font for subsequent text.
          ctx.font = "bold " + fontSize + "px Lucida Sans Unicode, monospace";
        }

        // Nickname + internal level above the box. Names longer than 16 chars
        // are truncated with an ellipsis so the overlay stays compact.
        ctx.font = 'bold ' + fontSize + 'px Lucida Sans Unicode, monospace';
        ctx.textAlign = 'center';
        ctx.textBaseline = 'middle';
        var label = '';
        if (settings.showNames) {
          var rawName = p.instance_vars && p.instance_vars[18];
          if (typeof rawName === 'string') label = rawName;
          else if (rawName !== undefined && rawName !== null) label = String(rawName);
          if (label.length > 16) label = label.substring(0, 16) + '…';
        }
        if (settings.showLevel) {
          label += (label ? ' ' : '') + '[L' + (enemyLevel + 1) + ']';
        }
        if (settings.showDistance) {
          // Inline distance next to the name/level so the value is always visible
          // even when the player is far away and the below-box label is small.
          label += (label ? ' ' : '') + Math.round(distance) + 'px';
        }
        if (label) {
          var textY = top - fontSize * 0.9;
          ctx.fillStyle = settings.textShadow;
          ctx.fillText(label, cx + 1, textY + 1);
          ctx.fillStyle = boxColor;
          ctx.fillText(label, cx, textY);
        }

        // Extra "★ TARGET" label for the active autohit target, drawn above
        // the nickname so the bot's intent is always visible in the overlay.
        if (isCurrentTarget && settings.currentTargetLabel) {
          var targetTextY = top - fontSize * 2.2;
          ctx.fillStyle = settings.textShadow;
          ctx.fillText(settings.currentTargetLabel, cx + 1, targetTextY + 1);
          ctx.fillStyle = settings.currentTargetLabelColor;
          ctx.fillText(settings.currentTargetLabel, cx, targetTextY);
          // Prominent distance line drawn above the ★ TARGET label so the
          // current target's range is visible at a glance. Uses the same
          // cyan tone as the TARGET text and a slightly larger font.
          if (settings.showDistance) {
            var targetDistStr = '▶ ' + Math.round(distance) + ' px';
            var targetDistY = top - fontSize * 3.2;
            var targetDistFontSize = Math.round(fontSize * 1.1);
            ctx.font = 'bold ' + targetDistFontSize + 'px Lucida Sans Unicode, monospace';
            ctx.fillStyle = settings.textShadow;
            ctx.fillText(targetDistStr, cx + 1, targetDistY + 1);
            ctx.fillStyle = settings.currentTargetLabelColor;
            ctx.fillText(targetDistStr, cx, targetDistY);
            // Reset font for the next player in the same frame.
            ctx.font = 'bold ' + fontSize + 'px Lucida Sans Unicode, monospace';
          }
        }

        // Distance below the box, rendered in its own colour for readability.
        // Bumped to a larger bold font and highlighted in cyan when the player
        // is the autohit's current target so the value is unmistakable.
        if (settings.showDistance) {
          var distStr = Math.round(distance) + ' px';
          var distY = bottom + fontSize * 0.9;
          var distFontSize = Math.round(fontSize * 1.15);
          ctx.font = 'bold ' + distFontSize + 'px Lucida Sans Unicode, monospace';
          ctx.fillStyle = settings.textShadow;
          ctx.fillText(distStr, cx + 1, distY + 1);
          ctx.fillStyle = isCurrentTarget
            ? settings.currentTargetLabelColor
            : settings.distanceTextColor;
          ctx.fillText(distStr, cx, distY);
          // Reset font so subsequent players in this frame render at the default size.
          ctx.font = 'bold ' + fontSize + 'px Lucida Sans Unicode, monospace';
        }

        // Optional thin HP bar above the name. Reads the standard Construct 2
        // health/max_health pair exposed on the instance; falls back silently
        // if those slots are absent on this build of the game.
        if (settings.showHpBar && p.instance_vars) {
          var hp = Number(p.instance_vars[7]);
          var maxHp = Number(p.instance_vars[8]);
          if (Number.isFinite(hp) && Number.isFinite(maxHp) && maxHp > 0) {
            var barW = Math.max(40, halfW * 2 * 0.7);
            var barH = Math.max(3, fontSize * 0.18);
            var ratio = Math.max(0, Math.min(1, hp / maxHp));
            var barX = cx - barW / 2;
            var barY = top - fontSize * 1.95;
            ctx.fillStyle = settings.hpBarBackground;
            ctx.fillRect(barX, barY, barW, barH);
            ctx.fillStyle = ratio < 0.35 ? settings.hpBarLowFill : settings.hpBarFill;
            ctx.fillRect(barX, barY, barW * ratio, barH);
            // Optional HP text "current/max" rendered below the bar.
            // Off by default to keep the overlay compact; enable from
            // console via window.espSettings.showHpText = true.
            if (settings.showHpText) {
              var hpTextFontSize = Math.max(9, (settings.hpTextFontSize || 10) * Math.min(scaleX, scaleY));
              ctx.font = "bold " + Math.round(hpTextFontSize) + "px Lucida Sans Unicode, monospace";
              ctx.textAlign = "center";
              ctx.textBaseline = "middle";
              var hpText = Math.round(hp) + "/" + Math.round(maxHp);
              var hpTextY = barY + barH + hpTextFontSize * 0.7;
              ctx.fillStyle = "rgba(0, 0, 0, 0.85)";
              ctx.fillText(hpText, cx + 1, hpTextY + 1);
              ctx.fillStyle = ratio < 0.35
                ? (settings.hpTextLowColor || "rgba(255, 200, 200, 0.95)")
                : (settings.hpTextColor || "#ffffff");
              ctx.fillText(hpText, cx, hpTextY);
              // Reset font for subsequent text.
              ctx.font = "bold " + fontSize + "px Lucida Sans Unicode, monospace";
            }
          }
        }

        // Reset global alpha so the next player is not affected by the dim.
        if (ctx.globalAlpha !== 1) ctx.globalAlpha = 1;
      }
    }

    // Renders the per-frame cooldown visualisation around the local player:
    //   - Dark full-circle background ring (always visible when autohit is on)
    //   - Bright arc that shrinks from full to empty as the cooldown elapses
    //     (red just after firing, yellow near the end of the cooldown)
    //   - Pulsing green ring when the swing is ready
    //   - Brief expanding yellow ring whenever a swing is actually fired
    //     (driven by window.swingFlash which the attack path sets)
    function drawCooldownIndicator(ctx, bounds, layer, scaleX, scaleY) {
      if (!window.modData.myInst || !window.autoHitEnabled) return;
      var myInst = window.modData.myInst;
      if (!myInst.layer) return;

      var now = performance.now();
      var lastSwing = window.lastAutoHitTime || 0;
      var elapsed = Math.max(0, now - lastSwing);
      var myLevel = window.getLevelFromInst(myInst);
      var cooldown = (window.cooldownTable && window.cooldownTable[myLevel]) || 200;
      var progress = Math.max(0, Math.min(1, elapsed / cooldown));

      var cx = bounds.left + (myInst.x - layer.viewLeft) * scaleX;
      var cy = bounds.top  + (myInst.y - layer.viewTop)  * scaleY;
      var sMin = Math.min(scaleX, scaleY);
      var ringRadius = 62 * sMin;
      var lineWidth = 8 * sMin;

      // Dark background ring (full circle, gives the progress a backdrop).
      // Stronger opacity (0.75) so the ring is visible on any background.
      ctx.beginPath();
      ctx.arc(cx, cy, ringRadius, 0, Math.PI * 2);
      ctx.strokeStyle = "rgba(0, 0, 0, 0.75)";
      ctx.lineWidth = lineWidth;
      ctx.stroke();

      // Center-text helper used in both the cooling and the ready states.
      function drawCenterText(text, fillColor) {
        var textSize = Math.max(11, 14 * sMin);
        ctx.font = "bold " + textSize + "px Lucida Sans Unicode, monospace";
        ctx.textAlign = "center";
        ctx.textBaseline = "middle";
        // Dark drop shadow for legibility against any background.
        ctx.fillStyle = "rgba(0, 0, 0, 0.9)";
        ctx.fillText(text, cx + 1, cy + 1);
        ctx.fillStyle = fillColor;
        ctx.fillText(text, cx, cy);
      }

      if (progress < 1) {
        var startAngle = -Math.PI / 2;
        var endAngle = startAngle + (1 - progress) * Math.PI * 2;

        // White glow underlay so the colored arc stays visible on bright
        // ground (snow, sand) as well as dark ground.
        ctx.beginPath();
        ctx.arc(cx, cy, ringRadius, startAngle, endAngle);
        ctx.strokeStyle = "rgba(255, 255, 255, 0.45)";
        ctx.lineWidth = lineWidth + 4 * sMin;
        ctx.lineCap = "round";
        ctx.stroke();

        // Main progress arc: red (just fired) -> orange -> yellow (almost ready).
        ctx.beginPath();
        ctx.arc(cx, cy, ringRadius, startAngle, endAngle);
        var r = Math.floor(244 + (255 - 244) * progress);
        var g = Math.floor(67 + (210 - 67) * progress);
        var b = Math.floor(54 + (50 - 54) * progress);
        ctx.strokeStyle = "rgb(" + r + "," + g + "," + b + ")";
        ctx.lineWidth = lineWidth;
        ctx.lineCap = "round";
        ctx.stroke();

        // Countdown in the centre so the remaining cooldown is readable
        // without having to interpret the arc length.
        var remainingMs = Math.max(0, Math.ceil(cooldown - elapsed));
        var remainingText = remainingMs >= 1000
          ? (remainingMs / 1000).toFixed(1) + "s"
          : remainingMs + "";
        drawCenterText(remainingText, "rgba(255, 255, 255, 0.95)");
      } else {
        // Ready: bright pulsing green ring with a wider glow halo so the
        // "ready to swing" state is unmistakable.
        var pulseAlpha = 0.85 + 0.15 * Math.sin(now / 200);
        // Outer glow.
        ctx.beginPath();
        ctx.arc(cx, cy, ringRadius, 0, Math.PI * 2);
        ctx.strokeStyle = "rgba(76, 175, 80, 0.45)";
        ctx.lineWidth = lineWidth + 6 * sMin;
        ctx.lineCap = "round";
        ctx.stroke();
        // Main ring.
        ctx.beginPath();
        ctx.arc(cx, cy, ringRadius, 0, Math.PI * 2);
        ctx.strokeStyle = "rgba(76, 175, 80, " + pulseAlpha + ")";
        ctx.lineWidth = lineWidth;
        ctx.lineCap = "round";
        ctx.stroke();
        drawCenterText("READY", "rgba(76, 175, 80, " + pulseAlpha + ")");
      }

      // Expanding swing flash on the most recent attack.
      if (window.swingFlash) {
        var flashElapsed = now - window.swingFlash.startTime;
        if (flashElapsed >= 0 && flashElapsed < window.swingFlash.duration) {
          var fp = flashElapsed / window.swingFlash.duration;
          var fr = ringRadius + fp * 70 * sMin;
          var fa = (1 - fp) * 0.85;
          ctx.beginPath();
          ctx.arc(cx, cy, fr, 0, Math.PI * 2);
          ctx.strokeStyle = "rgba(255, 235, 59, " + fa + ")";
          ctx.lineWidth = 3 * sMin;
          ctx.stroke();
        }
      }
    }

    // Draws the configured engine-derived radial weapon reach around the local player every frame.
    // The configured engine-derived polygon reach is used directly.
    // This also handles double-sword forms.
    function drawOverlay() {
        var overlay = window.autohitOverlay;
        var ctx = window.autohitOverlayCtx;
        var rt = window.runtime;
        if (!overlay || !ctx || !rt || !rt.canvas) return;

        var gameCanvas = rt.canvas;
        var bounds = gameCanvas.getBoundingClientRect();
        if (bounds.width === 0) return;

        var bw = window.innerWidth;
        var bh = window.innerHeight;
        if (overlay.width !== bw) overlay.width = bw;
        if (overlay.height !== bh) overlay.height = bh;

        ctx.clearRect(0, 0, bw, bh);

        if (window.overlayMode === 2) return;

        var myInst = window.modData && window.modData.myInst;
        if (!myInst || window.modData.state !== 'Playing') return;

        var layer = myInst.layer;
        if (!layer) return;

        var viewW = layer.viewRight - layer.viewLeft;
        var viewH = layer.viewBottom - layer.viewTop;
        if (viewW === 0 || viewH === 0) return;

        var scaleX = bounds.width / viewW;
        var scaleY = bounds.height / viewH;

        var cx = bounds.left + (myInst.x - layer.viewLeft) * scaleX;
        var cy = bounds.top  + (myInst.y - layer.viewTop)  * scaleY;

        var myLevel = window.getLevelFromInst(myInst);
        var ownReachInfo = getWeaponReachForPlayer(myInst, myLevel);
        var radiusPx = ownReachInfo.distance * scaleX;

        ctx.beginPath();
        ctx.arc(cx, cy, radiusPx, 0, Math.PI * 2);
        ctx.strokeStyle = 'rgba(76, 175, 80, 0.7)';
        ctx.lineWidth = 2;
        ctx.stroke();
        ctx.fillStyle = 'rgba(76, 175, 80, 0.03)';
        ctx.fill();

        if (window.overlayMode === 1) {
            window.closePlayerUIDS.forEach(function (playerUID) {
                var otherPlayer = window.runtime && window.runtime.getObjectByUID(playerUID);
                if (!otherPlayer || otherPlayer === myInst) return;

                var ecx = bounds.left + (otherPlayer.x - layer.viewLeft) * scaleX;
                var ecy = bounds.top  + (otherPlayer.y - layer.viewTop)  * scaleY;
                var enemyLevel = window.getLevelFromInst(otherPlayer);
                var enemyReachInfo = getWeaponReachForPlayer(otherPlayer, enemyLevel);
                var enemyRadiusPx = enemyReachInfo.distance * scaleX;

                ctx.beginPath();
                ctx.arc(ecx, ecy, enemyRadiusPx, 0, Math.PI * 2);
                ctx.strokeStyle = 'rgba(244, 67, 54, 0.5)';
                ctx.lineWidth = 1.5;
                ctx.stroke();
                ctx.fillStyle = 'rgba(244, 67, 54, 0.04)';
                ctx.fill();
            });
        }

        // Cooldown indicator — drawn inside the weapon-reach circles so the
        // player can read the swing state at a glance.
        if (window.autoHitEnabled) {
          drawCooldownIndicator(ctx, bounds, layer, scaleX, scaleY);
        }

        // ESP overlay — through-wall player awareness, drawn on top of the
        // weapon reach circles. Runs regardless of overlayMode so the user can
        // keep ESP enabled while the weapon-reach circles are turned off.
        if (window.espEnabled) {
          drawEspOverlay(ctx, layer, scaleX, scaleY, bounds);
        }
    }

    // Intercepts syncUpdateObject to track nearby enemy UIDs
    var oldSync = powerWS.Instance.prototype.syncUpdateObject;
    powerWS.Instance.prototype.syncUpdateObject = function (data_) {
      var serverUID = parseInt(data_[0]);
      if (this.objectsMap && (!window.getUidBySUID || !window.getTagBySUID)) {
        window.getUidBySUID = this.objectsMap.getUidBySUID;
        window.getTagBySUID = this.objectsMap.getTagBySUID;
      }

      // Let the original engine update the instance first.
      // The previous version sampled stale coordinates before oldSync ran.
      var existedBefore = this.objectsMap && this.objectsMap.existsBySUID(serverUID);
      var objectTag = existedBefore ? this.objectsMap.getTagBySUID(serverUID) : undefined;
      var uid = existedBefore ? this.objectsMap.getUidBySUID(serverUID) : undefined;
      var result = oldSync.apply(this, arguments);

      if (!this.objectsMap || !this.objectsMap.existsBySUID(serverUID)) return result;
      objectTag = this.objectsMap.getTagBySUID(serverUID);
      uid = this.objectsMap.getUidBySUID(serverUID);
      var inst = this.runtime.getObjectByUID(uid);
      if (!inst) return result;

      // Feed only real post-sync engine snapshots into the motion tracker
      // so the smart trigger can project target positions at contact time.
      updateSnapshotMotion(inst, performance.now());

      if (window.modData.mySUID == serverUID) window.modData.myInst = inst;
      if (objectTag == "p" && inst != window.modData.myInst) {
        window.closePlayerUIDS.add(uid);
      }
      if (data_.length === 1) {
        window.closePlayerUIDS.delete(uid);
      }
      return result;
    };

    // Intercepts outgoing WS packets — extracts session data and patches the play packet
    function interceptSend(workerData) {
      if (!workerData) return workerData;
      if (workerData.action === "send" && workerData.data && workerData.data.d !== null) {
        switch (workerData.data.a) {
          case "set_nick":
            window.modData.nickname = workerData.data.d.nick;
            break;
          case "handshake":
            window.modData.accountUUID = workerData.data.d.uuid;
            break;
          case "play":
            if (!workerData.data.d) workerData.data.d = {};
            workerData.data.d.b = 1;
            break;
        }
      }
      return workerData;
    }

    // Intercepts incoming WS packets — populates modData with game state
    function interceptInfo(event) {
      var action = event[0];
      var data = event[1];
      switch (action) {
        case "game":
          window.modData.mySUID = data.my_player_uid;
          window.modData.gameMode = data.map.id;
          window.modData.mapBorders = { height: data.map.height, width: data.map.width };
          window.modData.instance = data.instance;
          window.modData.gameDelay = data.delay;
          window.modData.isAlive = true;
          window.modData.inGame = true;
          window.modData.timelimit = data.ts.v;
          break;
        case "state":
          window.modData.state = data.v;
          break;
        case "top":
          if (data.length > 5) window.modData.mySUID = data[5].uid;
          break;
        case "end":
        case "result":
          endGame();
          break;
      }
      return event;
    }

    // Patches wsWorker once it becomes available — hooks onmessage and postMessage
    var checkInterval = setInterval(function () {
      if (wsWorker && isWSReady && wsWorker.onmessage) {
        var originalOnMessage = wsWorker.onmessage;
        window.wsWorker = wsWorker;
        wsWorker.onmessage = function (event) {
          if (event.data.action === "message") {
            var action = event.data.data[0];
            if (typeof action === "string") {
              event.data.data = interceptInfo(event.data.data);
              if (!event.data.data) return;
            }
          }
          return originalOnMessage.apply(this, arguments);
        };
        var oldPost = wsWorker.postMessage;
        wsWorker.postMessage = function (workerData) {
          workerData = interceptSend(workerData);
          return oldPost.apply(this, arguments);
        };
        clearInterval(checkInterval);
      }
    }, 500);

    window.getLevelFromInst = function (instance) {
      if (!instance) return 0;
      return instance.instance_vars[window.dynamicIndices.level];
    };

    // UI elements — closest enemy label and status panel

    var closestPlayerLabel = document.createElement("span");
    closestPlayerLabel.style.cssText = "position:absolute;top:10px;right:300px;font-family:Lucida Sans Unicode;pointer-events:none;";
    // Default to the lobby indicator so the label is never blank between
    // matches. The label is replaced with the closest enemy name in AllLoop
    // once a match starts, and reset back to this in endGame(). The same
    // plain style is used in both states so the panel does not jump sizes.
    closestPlayerLabel.textContent = "Sảnh chờ";
    window.closePlayerLabel = closestPlayerLabel;
    document.body.appendChild(closestPlayerLabel);

    var statusDisplay = document.createElement("div");
    statusDisplay.style.cssText = "position:fixed;bottom:10px;right:10px;z-index:9999;font-family:Lucida Sans Unicode,monospace;font-size:13px;background:rgba(0,0,0,0.65);padding:6px 10px;border-radius:6px;line-height:1.7;pointer-events:none;";
    document.body.appendChild(statusDisplay);
    window.statusDisplay = statusDisplay;

    window.bigCharacterMode = false;

    // HUD — shows autohit state, cooldown, nearest enemy distance.
    // The panel uses the same structure in lobby and in-game; only the
    // data values (Raw Dist / Adj Diff / CD State) differ.
    function updateStatusDisplay() {
      if (!window.statusDisplay) return;
      var hitLabel = window.autoHitEnabled ? "ON" : "OFF";
      var hitColor = window.autoHitEnabled ? "#81c784" : "#e57373";
      var bigCharLabel = window.bigCharacterMode ? "ON" : "OFF";
      var bigCharColor = window.bigCharacterMode ? "#81c784" : "#e57373";
      var overlayLabels = ["OWN", "ALL", "OFF"];
      var overlayColors = ["#81c784", "#64b5f6", "#e57373"];
      var overlayLabel = overlayLabels[window.overlayMode] || "—";
      var overlayColor = overlayColors[window.overlayMode] || "#ccc";
      var d = window.debugClosestData || {};
      var hasTarget = d.rawDist !== undefined;

      // Cooldown display. Falls back to "—" when no local player exists
      // (lobby) so the panel renders the same rows in both states.
      var cdLabel = "—";
      var cdColor = "#888";
      var cdProgress = 0;
      if (window.modData.myInst) {
          var lv = window.getLevelFromInst(window.modData.myInst);
          var maxCD = window.cooldownTable[lv] || 200;
          var elapsed = performance.now() - (window.lastAutoHitTime || 0);
          cdProgress = Math.max(0, Math.min(100, (elapsed / maxCD) * 100));
          if (elapsed >= maxCD) {
              cdLabel = "✓ Ready";
              cdColor = "#81c784";
          } else {
              cdLabel = Math.ceil(maxCD - elapsed) + " ms";
              cdColor = cdProgress > 75 ? "#ffeb3b" : "#e57373";
          }
      }

      var adjColor = !hasTarget ? "#888"
        : (d.adjDiff !== undefined && d.adjDiff < -(d.dynBuffer || 15) ? "#ff9800"
          : (d.adjDiff < 0 ? "#ffeb3b" : "#81c784"));

      window.statusDisplay.innerHTML =
        '<span style="color:#ccc;">[W] AutoHit: </span><span style="color:' + hitColor + ';font-weight:bold;">' + hitLabel + "</span><br>" +
        '<span style="color:#ccc;">[C] Big Targets: </span><span style="color:' + bigCharColor + ';font-weight:bold;">' + bigCharLabel + "</span><br>" +
        '<span style="color:#ccc;">[Q] Overlay: </span><span style="color:' + overlayColor + ';font-weight:bold;">' + overlayLabel + "</span><br>" +
        '<span style="color:#ccc;">[E] ESP: </span><span style="color:' + (window.espEnabled ? '#81c784' : '#e57373') + ';font-weight:bold;">' + (window.espEnabled ? 'ON' : 'OFF') + "</span>" +
        '<hr style="border:none;border-top:1px solid #444;margin:3px 0;">' +
        '<span style="color:#888;">Raw Dist: </span><span style="color:#ddd;">' + (hasTarget ? d.rawDist + " px" : "—") + "</span><br>" +
        '<span style="color:#888;">Adj Diff: </span><span style="color:' + adjColor + ';">' + (hasTarget ? d.adjDiff : "—") + "</span><br>" +
        '<span style="color:#888;">CD State: </span><span style="color:' + cdColor + ';font-weight:bold;">' + cdLabel + "</span><br>" +
        '<div style="height:6px;background:rgba(0,0,0,0.55);border-radius:3px;margin-top:3px;width:140px;overflow:hidden;">' +
          '<div style="height:100%;width:' + cdProgress.toFixed(1) + '%;background:' + cdColor + ';border-radius:3px;transition:width 80ms linear, background 200ms linear;"></div>' +
        '</div>';
    }
    updateStatusDisplay();
    setInterval(updateStatusDisplay, 50);

    // Real player clicks count toward cooldown
    var _gameCanvas = window.runtime && window.runtime.canvas;
    if (_gameCanvas) {
      _gameCanvas.addEventListener("mousedown", function (e) {
        if (e.isTrusted && e.button === 0 && window.modData.state === "Playing") {
          window.lastAutoHitTime = performance.now();
        }
      }, { capture: true, passive: true });
    }

    // Keybindings: W = autohit toggle, C = big character mode, Q = overlay toggle, N = HUD toggle
    document.addEventListener("keydown", function (event) {
      if (event.key === "c" || event.key === "C") {
        window.bigCharacterMode = !window.bigCharacterMode;
        if (window.netTuning) {
          window.netTuning.levelFilter = window.bigCharacterMode ? "big-only" : "all";
        }
        console.log("[AutoHit] Big Target mode:", window.bigCharacterMode ? "ON" : "OFF",
            "(only attacks enemies within 5 levels of your own)");
        updateStatusDisplay();
        event.preventDefault();
      }
      if (event.key === "w" || event.key === "W") {
        window.autoHitEnabled = !window.autoHitEnabled;
        if (!window.autoHitEnabled) {
          // Clear the predicted-target highlight so the ESP stops advertising
          // a swing that will never fire while autohit is off.
          window.predictedTargetUID = null;
          window.predictedTargetName = "";
          window.predictedTargetLevel = 0;
        }
        updateStatusDisplay();
        event.preventDefault();
      }
      if (event.key === "q" || event.key === "Q") {
        window.overlayMode = (window.overlayMode + 1) % 3;
        event.preventDefault();
      }
      if (event.key === "n" || event.key === "N") {
        if (window.statusDisplay) {
          window.statusDisplay.style.display = window.statusDisplay.style.display === 'none' ? '' : 'none';
        }
        event.preventDefault();
      }
      if (event.key === "e" || event.key === "E") {
        window.espEnabled = !window.espEnabled;
        console.log("[AutoHit] ESP overlay:", window.espEnabled ? "ON" : "OFF");
        updateStatusDisplay();
        event.preventDefault();
      }
    });

    // Executes an attack toward the enemy's current engine-frame position.
    // In non-heuristic mode a velocity-based lead is added to the click point
    // so the swing lands where the target is expected to be at contact time.
    function executeAttack(targetInst, out) {
      if (!window.modData.myInst || !targetInst) return;
      if (!out) out = processPlayer(window.modData.myInst, targetInst);

      var dx, dy;
      if (out && typeof out.aimDx === 'number') {
        // Heuristic mode already produced a blended aim vector.
        dx = out.aimDx;
        dy = out.aimDy;
      } else {
        dx = targetInst.x - window.modData.myInst.x;
        dy = targetInst.y - window.modData.myInst.y;

        // Non-heuristic mode: aim lead from per-player motion snapshots.
        if (window.netTuning && window.netTuning.aimLeadEnabled && window._motionSnapshots) {
          var mySnap = window._motionSnapshots.get(window.modData.myInst.uid);
          var tgtSnap = window._motionSnapshots.get(targetInst.uid);
          if (mySnap && tgtSnap) {
            var relVx = (tgtSnap.vx || 0) - (mySnap.vx || 0);
            var relVy = (tgtSnap.vy || 0) - (mySnap.vy || 0);
            var measuredPing = Number(window.smoothedPing || window.ping || 0);
            var leadMs = Math.min(
              window.netTuning.aimLeadMaxMs || 120,
              (window.netTuning.aimLeadBaseMs || 35)
                + measuredPing * (window.netTuning.aimLeadPingScale || 0.4)
            );
            var leadSec = leadMs / 1000;
            dx += relVx * leadSec;
            dy += relVy * leadSec;
          }
        }
      }
      var swingDeg = getSword(out.myLevel).degrees || 130;
      var adjustedAngleRad = Math.atan2(dy, dx) + (swingDeg * Math.PI / 180);

      fireCanvasAttack(adjustedAngleRad);
    }

    // Fires the attack: injects angle into engine memory, plays visual, sends network packet
    function fireCanvasAttack(angleRad) {
      var myInst = window.modData.myInst;
      var canvas = window.runtime && window.runtime.canvas;
      if (!canvas || !myInst) return;

      // write angle so character turns manually
      if (myInst.instance_vars && myInst.instance_vars[INDEX_ANGLE_VAR] !== undefined) {
        myInst.instance_vars[INDEX_ANGLE_VAR] = angleRad;
      }
      if (typeof myInst.angle !== 'undefined') myInst.angle = angleRad;

      // we don't send mnouse down packet
      // Send the packet first; visual mouse movement is secondary.
      if (window.queueWasmClick) {
        var angleDeg = Math.round(((angleRad * 180 / Math.PI) % 360 + 360) % 360);
        window.queueWasmClick(angleDeg);
      }

      var bounds = canvas.getBoundingClientRect();
      var clickX = bounds.left + canvas.width * 0.5 + Math.cos(angleRad) * 300;
      var clickY = bounds.top + canvas.height * 0.5 + Math.sin(angleRad) * 300;
      canvas.dispatchEvent(new MouseEvent('mousemove', { bubbles: true, clientX: clickX, clientY: clickY }));
    }

    var minDistanceForNearby = 3000;

    // Reads only the current engine-frame state.
    function processPlayer(myInst, opponentInst) {
      var out = {};
      out.pX = opponentInst.x;
      out.pY = opponentInst.y;

      out.dx = out.pX - myInst.x;
      out.dy = out.pY - myInst.y;
      out.distance = Math.sqrt(out.dx * out.dx + out.dy * out.dy);
      out.angle = (Math.atan2(out.dy, out.dx) * (180 / Math.PI) + 360) % 360;
      out.myLevel = window.getLevelFromInst(myInst);
      out.name = opponentInst.instance_vars[18];
      out.myTeam = myInst.instance_vars[36];
      out.enemyTeam = opponentInst.instance_vars[36];
      return out;
    }

    // Enemy hitbox radius derived from game internal measurements.
    // Level 0 has a special 40-unit radius; from internal level 35 upward the body radius caps at 206.4.
    function calculateTargetRadius(level) {
      if (level <= 0) return 40;
      return Math.min(38.4 + level * 4.8, 206.4);
    }

    // Returns true if an enemy at `enemyLevel` is allowed by the current
    // netTuning.levelFilter setting. Centralised so the attack loop and any
    // future UI surface agree on the same rule.
    function passesLevelFilter(myLevel, enemyLevel) {
      var filter = (window.netTuning && window.netTuning.levelFilter) || "all";
      switch (filter) {
        case "all":             return true;
        case "big-only":        return enemyLevel >= myLevel - 5;
        case "small-only":      return enemyLevel < myLevel;
        case "bigger-only":     return enemyLevel > myLevel;
        case "same-only":       return enemyLevel === myLevel;
        case "same-or-smaller": return enemyLevel <= myLevel;
        case "same-or-bigger":  return enemyLevel >= myLevel;
        default:                return true;
      }
    }

    // Smart trigger — an extra gate on top of the geometry check. Only
    // fires when the swing is actually going to connect, not just when
    // the target happens to graze the FOV this frame.
    //
    //   shouldFire: true if the smart trigger approves the swing
    //   reason:     short string for debug HUD / console
    //   aimDx, aimDy: predicted aim vector at contact time (so the click
    //                 leads the target to where the swing will land)
    //   frameCount: how many consecutive in-range frames the target has
    function evaluateSmartTrigger(myInst, targetInst, totalHitRadius, radialClosingSpeed) {
      var tuning = window.netTuning || {};
      if (tuning.smartTriggerEnabled === false) {
        return { shouldFire: true, reason: "disabled", aimDx: null, aimDy: null, frameCount: 0 };
      }
      if (!window._triggerFrames) window._triggerFrames = new Map();

      var uid = targetInst.uid;
      var now = performance.now();
      var dx = targetInst.x - myInst.x;
      var dy = targetInst.y - myInst.y;
      var dist = Math.hypot(dx, dy);
      var inRange = dist <= totalHitRadius;

      // Update per-target frame counter. Out-of-range entries decay after
      // a short grace window so a brief dip (ping spike, sprite rounding)
      // does not reset the entire confirmation.
      var data = window._triggerFrames.get(uid);
      if (inRange) {
        if (!data) {
          data = { count: 0, firstTime: now, lastTime: now };
        }
        data.count++;
        data.lastTime = now;
        window._triggerFrames.set(uid, data);
      } else if (data) {
        var timeoutMs = tuning.smartTriggerOutOfRangeTimeout || 150;
        if (now - data.lastTime > timeoutMs) {
          window._triggerFrames.delete(uid);
          data = null;
        }
      }

      if (!data) {
        return { shouldFire: false, reason: "not-in-range", aimDx: null, aimDy: null, frameCount: 0 };
      }

      // Check 1: multi-frame confirmation.
      var requiredFrames = tuning.smartTriggerFrames || 2;
      if (data.count < requiredFrames) {
        return {
          shouldFire: false,
          reason: "frame " + data.count + "/" + requiredFrames,
          aimDx: null, aimDy: null, frameCount: data.count
        };
      }

      // Check 2: predictive geometry. Project the target forward to where
      // it will be at contact time and confirm the projected position is
      // still inside the trigger radius.
      var mySnap = window._motionSnapshots && window._motionSnapshots.get(myInst.uid);
      var tgtSnap = window._motionSnapshots && window._motionSnapshots.get(targetInst.uid);
      var relVx = (tgtSnap ? tgtSnap.vx : 0) - (mySnap ? mySnap.vx : 0);
      var relVy = (tgtSnap ? tgtSnap.vy : 0) - (mySnap ? mySnap.vy : 0);

      var ping = Number(window.smoothedPing || window.ping || 0);
      var contactMs = Math.max(60,
        (tuning.smartTriggerContactMs || 100)
          + ping * (tuning.smartTriggerContactPingScale || 0.3)
      );
      var contactSec = contactMs / 1000;

      var projDx = dx + relVx * contactSec;
      var projDy = dy + relVy * contactSec;
      var projDist = Math.hypot(projDx, projDy);

      if (projDist > totalHitRadius) {
        return {
          shouldFire: false,
          reason: "predicted " + Math.round(projDist) + ">" + Math.round(totalHitRadius),
          aimDx: null, aimDy: null, frameCount: data.count
        };
      }

      // Check 3: tangential motion guard. Targets moving perpendicular to
      // the attack line can graze the FOV for one or two frames and then
      // be gone — require more in-range frames before committing.
      var tangentialSpeed = Math.hypot(relVx, relVy);
      if (tangentialSpeed > 50) {
        var closingRatio = radialClosingSpeed / tangentialSpeed;
        var threshold = tuning.smartTriggerTangentialRatio || 0.3;
        var tangentialFrames = tuning.smartTriggerTangentialFrames || 4;
        if (closingRatio < threshold && data.count < tangentialFrames) {
          return {
            shouldFire: false,
            reason: "tangential " + Math.round(closingRatio * 100) + "% < " + Math.round(threshold * 100) + "%",
            aimDx: null, aimDy: null, frameCount: data.count
          };
        }
      }

      return {
        shouldFire: true,
        reason: "ok",
        aimDx: tuning.smartTriggerUsePredictedAim !== false ? projDx : dx,
        aimDy: tuning.smartTriggerUsePredictedAim !== false ? projDy : dy,
        frameCount: data.count,
        projectedDist: projDist
      };
    }

    // Cleans up _triggerFrames so the map does not grow unbounded.
    // Called once per AllLoop; cheap when the map is small.
    function cleanupTriggerFrames() {
      if (!window._triggerFrames) return;
      var now = performance.now();
      var max = (window.netTuning && window.netTuning.smartTriggerMaxTracked) || 200;
      if (window._triggerFrames.size <= max) return;
      window._triggerFrames.forEach(function (data, uid) {
        if (now - data.lastTime > 1000) {
          window._triggerFrames.delete(uid);
        }
      });
    }

    // Console helper: dump every tracked target's smart-trigger state.
    window.smartTriggerDiagnostic = function () {
      if (!window._triggerFrames) {
        console.log("[Smart Trigger] Not initialised yet.");
        return [];
      }
      var now = performance.now();
      var rows = [];
      window._triggerFrames.forEach(function (data, uid) {
        rows.push({
          uid: uid,
          frameCount: data.count,
          ageMs: Math.round(now - data.firstTime),
          sinceLastUpdateMs: Math.round(now - data.lastTime)
        });
      });
      rows.sort(function (a, b) { return b.frameCount - a.frameCount; });
      console.log("[Smart Trigger] " + rows.length + " target(s) tracked");
      if (rows.length) console.table(rows);
      return rows;
    };

    // Main per-frame loop — runs on every engine tick while state is Playing.
    function AllLoop() {
      // Fallback self-player detection if syncUpdateObject hasn't resolved myInst yet
      if (!window.modData.myInst && window.runtime && window.runtime.types_by_index) {
          var playerType = null;
          for (var i = 0; i < window.runtime.types_by_index.length; i++) {
              var t = window.runtime.types_by_index[i];
              if (t && t.instvar_sids && t.instvar_sids.length === 72) {
                  playerType = t;
                  break;
              }
          }
          if (playerType && playerType.instances && playerType.instances.length > 0) {
              var scrollX = window.runtime.running_layout.scrollX;
              var scrollY = window.runtime.running_layout.scrollY;
              var bestInst = null, minDist = Infinity;
              for (var j = 0; j < playerType.instances.length; j++) {
                  var p = playerType.instances[j];
                  var d = Math.sqrt((p.x - scrollX) * (p.x - scrollX) + (p.y - scrollY) * (p.y - scrollY));
                  if (d < minDist) {
                      minDist = d;
                      bestInst = p;
                  }
              }
              if (bestInst) {
                  window.modData.myInst = bestInst;
                  console.log("[AutoHit] Sikeresen elkaptuk a saját karaktert a motorból!");
              }
          }
      }

      // Spawn protection check — t109 bubble pinned to our character means we cannot attack
      if (window.modData.myInst && window.runtime && window.runtime.types_by_index) {
          var myX = window.modData.myInst.x;
          var myY = window.modData.myInst.y;
          for (var ti = 0; ti < window.runtime.types_by_index.length; ti++) {
              var t109type = window.runtime.types_by_index[ti];
              if (t109type && t109type.name === 't109' && t109type.instances) {
                  for (var bi = 0; bi < t109type.instances.length; bi++) {
                      var bubble = t109type.instances[bi];
                      if (Math.abs(bubble.x - myX) < 5 && Math.abs(bubble.y - myY) < 5) {
                          return;
                      }
                  }
                  break;
              }
          }
      }

      var minDistance = Infinity;
      var closestPlayerUID;
      var closestName = "";

      var bestTargetInst = null;
      var bestTargetOut = null;
      var maxTargetLevel = -1;
      var bestTargetDist = Infinity;
      var closestOut = null;
      var closestInst = null;

      var now = performance.now();
      if (window.modData.myInst) {
          // Scout: start on first available frame, tick every frame until all confirmed.
          scout.start();
          scout.tick(window.modData.myInst);
      }

      var belsoszint = window.modData.myInst ? window.getLevelFromInst(window.modData.myInst) : 0;
      var currentCooldown = window.cooldownTable[belsoszint] || 200;

      // cooldown check
      var isReadyToSwing = window.modData.myInst && (now - (window.lastAutoHitTime || 0) > currentCooldown);
      var mySword = getSword(belsoszint);
      var myWeaponReachInfo = window.modData.myInst
        ? getWeaponReachForPlayer(window.modData.myInst, belsoszint)
        : { distance: mySword.distance, source: "fallback-table" };
      var myWeaponReach = myWeaponReachInfo.distance;

      var playerUidsToDelete = [];
      window.closePlayerUIDS.forEach(function (playerUID) {
          if (!window.modData.myInst) return;
          var otherPlayer = window.runtime && window.runtime.getObjectByUID(playerUID);
          if (!otherPlayer || otherPlayer === window.modData.myInst) {
              playerUidsToDelete.push(playerUID);
              return;
          }
          // spawn
          var isProtected = false;
          var types = window.runtime.types_by_index;
          for (var _t = 0; _t < types.length; _t++) {
              // bubble object in c2
              if (types[_t] && types[_t].name === "t109" && types[_t].instances) {
                  var bubbles = types[_t].instances;
                  //see all active bubble
                  for (var _b = 0; _b < bubbles.length; _b++) {
                      // coordinate check
                      if (Math.abs(bubbles[_b].x - otherPlayer.x) < 5 && Math.abs(bubbles[_b].y - otherPlayer.y) < 5) {
                          isProtected = true;
                          break;
                      }
                  }
                  break; // found it
              }
          }

          if (isProtected) {
              return; // don't hit bubble
          }
          var out = processPlayer(window.modData.myInst, otherPlayer);

          if (window.modData.gameMode === 1 && out.myTeam === out.enemyTeam) {
              return;
          }

          if (out.distance > minDistanceForNearby) {
              playerUidsToDelete.push(playerUID);
              return;
          }

          if (out.distance < minDistance) {
              minDistance = out.distance;
              closestPlayerUID = playerUID;
              closestName = out.name;
              closestOut = out;
              closestInst = otherPlayer;
          }

          if (window.autoHitEnabled) {
              var enemyLevel = window.getLevelFromInst(otherPlayer);

              if (!passesLevelFilter(belsoszint, enemyLevel)) {
                  return;
              }

              // Body-radius bonus for lower-level targets. Smaller enemies are
              // easier to hit dead-on, so a small bonus gives the trigger a
              // safety margin without firing wildly early. Bonus only applies
              // when the enemy is below our level; equal/higher levels get 0.
              var levelDiff = belsoszint - enemyLevel;
              var bodyRadiusBonus = levelDiff > 0
                ? Math.min(
                    window.netTuning.smallerTargetBodyBonusCap || 12,
                    levelDiff * (window.netTuning.smallerTargetBodyBonusPerLevel || 1.5)
                  )
                : 0;

              var totalHitRadius = myWeaponReach
                + calculateTargetRadius(enemyLevel) * window.netTuning.targetRadiusScale
                + (window.netTuning.targetRadiusPadding || 0)
                + bodyRadiusBonus;

              // Velocity-based closing speed. Positive only when the target
              // is actually approaching (closing the gap). 0 for stationary
              // or receding targets. out.dx/out.dy are added to processPlayer's
              // return object specifically for this lookup.
              var radialClosingSpeed = 0;
              if (window._motionSnapshots && out.distance > 0 && typeof out.dx === "number") {
                var mySnapTmp = window._motionSnapshots.get(window.modData.myInst.uid);
                var tgtSnapTmp = window._motionSnapshots.get(otherPlayer.uid);
                if (mySnapTmp && tgtSnapTmp) {
                  var relVx = (tgtSnapTmp.vx || 0) - (mySnapTmp.vx || 0);
                  var relVy = (tgtSnapTmp.vy || 0) - (mySnapTmp.vy || 0);
                  radialClosingSpeed = Math.max(0,
                    -((out.dx * relVx + out.dy * relVy) / out.distance)
                  );
                }
              }

              // Reach-aware pre-fire. A fixed -8 px pre-fire becomes a tiny
              // fraction of a 1100 px trigger and the target slips past before
              // the swing lands. Scale the inset up for weapons shorter than
              // reachPrefireReference so the same time delay represents a
              // similar fraction of the trigger window at every reach length.
              var baseInset = (window.netTuning.currentDistanceInset || 0);
              var reachScale = 1;
              if (window.netTuning.reachAwarePrefire) {
                var refReach = window.netTuning.reachPrefireReference || 250;
                var minReach = window.netTuning.reachPrefireMin || 50;
                reachScale = myWeaponReach < refReach
                  ? refReach / Math.max(minReach, myWeaponReach)
                  : 1;
              }
              var scaledInset = baseInset * reachScale;

              // Time-based closing lead. The pre-fire window scales with ping
              // so high-latency connections get a proportionally larger lead,
              // and the closing-speed term is then added on top.
              var pingMs = Number(window.smoothedPing || window.ping || 0);
              var preFireMs = Math.min(
                window.netTuning.preFireMaxMs || 120,
                (window.netTuning.preFireBaseMs || 35) + pingMs * (window.netTuning.preFirePingScale || 0.5)
              );
              var closingLeadPx = Math.min(
                window.netTuning.closingLeadCap || 40,
                radialClosingSpeed * (preFireMs / 1000) * (window.netTuning.closingLeadScale || 0.5)
              );

              // Dynamic pre-fire. Base inset (reach-scaled) minus time-based
              // closing lead. Negative = fire before geometric contact.
              //
              // Heuristic-style insets are baked in here (no A/B toggle). The
              // old visibleHeuristic mode was useful but redundant with the
              // smart trigger — its predictive aim, time-based pre-fire, and
              // closing lead are now applied unconditionally so the autohit
              // always behaves like the "ON" variant of the old heuristic.
              //   1. Level-based inset: stronger attacker (higher level) is
              //      harder to whiff on, so a slightly tighter trigger is OK.
              //   2. Contact inset by level relation: small/large/equal.
              //   3. Long-reach extra inset for short weapons vs smaller
              //      targets, so we do not fire while the sword is still
              //      travelling across a large empty distance.
              var ht = window.visibleHeuristicTuning || {};
              var targetRelation = belsoszint > enemyLevel ? "smaller"
                : (belsoszint < enemyLevel ? "larger" : "equal");

              var heuristicLevelInset = 0;
              if (belsoszint > enemyLevel) {
                var diff = belsoszint - enemyLevel;
                heuristicLevelInset = Math.min(
                  ht.strongerAttackerInsetCap || 24,
                  diff * (ht.strongerAttackerInsetPerLevel || 8)
                );
              } else if (belsoszint < enemyLevel) {
                heuristicLevelInset = ht.smallerAttackerInset || 10;
              }

              var heuristicContactInset = targetRelation === "smaller"
                ? (ht.contactInsetVsSmallerTarget || 16)
                : (targetRelation === "larger"
                    ? (ht.contactInsetVsLargerTarget || 18)
                    : (ht.contactInsetVsEqualTarget || 16));

              var smallerTargetLongReachExtraInset = 0;
              if (targetRelation === "smaller") {
                var refReachHeur = ht.smallerTargetLongReachReference || 650;
                smallerTargetLongReachExtraInset = Math.min(
                  ht.smallerTargetLongReachExtraInsetCap || 14,
                  Math.max(0, myWeaponReach - refReachHeur)
                    * (ht.smallerTargetLongReachExtraInsetScale || 0.035)
                );
              }

              // Positive values — added to dynamicInset, tightening the trigger.
              var totalHeuristicInsets = heuristicLevelInset
                + heuristicContactInset
                + smallerTargetLongReachExtraInset;

              var dynamicInset = scaledInset - closingLeadPx + totalHeuristicInsets;
              var usableHitRadius = Math.max(1, totalHitRadius - dynamicInset);

              // Smaller-target range ceiling. Caps the trigger so the autohit
              // does not fire until the smaller target is actually inside the
              // guaranteed-penetration zone. Without this, a long sword with
              // a small target can trigger while the sword is still travelling.
              if (targetRelation === "smaller") {
                var guaranteedInset = ht.smallerTargetGuaranteedPenetrationInset || 26;
                var smallerTargetCeiling = Math.max(1,
                  totalHitRadius - guaranteedInset - smallerTargetLongReachExtraInset
                );
                if (usableHitRadius > smallerTargetCeiling) {
                  usableHitRadius = smallerTargetCeiling;
                }
              }

              if (out.distance <= usableHitRadius) {
                  // Smart trigger — sits on top of the geometry check. The
                  // legacy line "fire as soon as we're in range" causes a
                  // lot of ghost hits when the target only grazes the FOV
                  // for a single frame. The smart trigger instead requires
                  // multi-frame confirmation, projects the target forward
                  // to where it will be at contact time, and rejects
                  // tangential "slip past" targets.
                  var smart = evaluateSmartTrigger(
                    window.modData.myInst,
                    otherPlayer,
                    totalHitRadius,
                    radialClosingSpeed
                  );
                  if (!smart.shouldFire) {
                    out.smartTrigger = smart;
                    return;
                  }
                  out.smartTrigger = smart;
                  // Use the predicted aim vector when the smart trigger
                  // produced one; fall back to the heuristic's aim if
                  // visible-heuristic mode is on, otherwise current pos.
                  if (smart.aimDx !== null && smart.aimDy !== null) {
                    out.aimDx = smart.aimDx;
                    out.aimDy = smart.aimDy;
                  }

                  var isBetterTarget = false;
                  if (window.netTuning.targetSelection === "highest-level") {
                      if (enemyLevel > maxTargetLevel) {
                          isBetterTarget = true;
                          maxTargetLevel = enemyLevel;
                      }
                  } else {
                      // 'closest' (default): lower distance wins, ties broken by level.
                      if (out.distance < bestTargetDist ||
                          (out.distance === bestTargetDist && enemyLevel > maxTargetLevel)) {
                          isBetterTarget = true;
                          bestTargetDist = out.distance;
                          maxTargetLevel = enemyLevel;
                      }
                  }
                  if (isBetterTarget) {
                      bestTargetInst = otherPlayer;
                      out.triggerRadius = usableHitRadius;
                      out.currentDistanceOnly = true;
                      bestTargetOut = out;
                  }
              }
          }
      });

      for (var k = 0; k < playerUidsToDelete.length; k++) window.closePlayerUIDS.delete(playerUidsToDelete[k]);

      // Publish the next target every frame so the ESP overlay can highlight
      // the bot's intended victim ahead of time — including from OUTSIDE
      // the current attack range. Without this fallback the cyan box only
      // appears the moment an enemy is already in range; with it the
      // highlight follows the closest approaching enemy so the user can
      // see who is about to become a target.
      //
      // Priority:
      //   1. In-range target the bot is about to swing at (preferred).
      //   2. Closest enemy in closePlayerUIDS — the next target as soon
      //      as it enters attack range.
      //   3. None.
      if (bestTargetInst) {
          window.predictedTargetUID = bestTargetInst.uid;
          window.predictedTargetName = bestTargetOut.name || "";
          window.predictedTargetLevel = window.getLevelFromInst(bestTargetInst);
      } else if (closestInst) {
          window.predictedTargetUID = closestInst.uid;
          window.predictedTargetName = closestName || "";
          window.predictedTargetLevel = window.getLevelFromInst(closestInst);
      } else {
          window.predictedTargetUID = null;
          window.predictedTargetName = "";
          window.predictedTargetLevel = 0;
      }

      if (bestTargetInst && bestTargetOut && isReadyToSwing) {
          window.lastAutoHitTime = now;
          // Trigger the brief expanding yellow flash around the local player
          // so the swing can be seen landing even when the target is offscreen.
          window.swingFlash = { startTime: now, duration: 280 };
          // Remember the last actually-attacked target for the debug HUD.
          window.currentTargetUID = bestTargetInst.uid;
          window.currentTargetName = bestTargetOut.name || "";
          window.currentTargetLevel = window.getLevelFromInst(bestTargetInst);
          executeAttack(bestTargetInst, bestTargetOut);
      }

      window.closestPlayerUID = closestPlayerUID;
      if (window.closestPlayerUID) window.closePlayerLabel.textContent = closestName;

      // --- DEBUG DATA COLLECTION ---
      if (window.closestPlayerUID && closestOut && closestInst) {
          var dbgLevelDiff = belsoszint - window.getLevelFromInst(closestInst);
          var dbgBodyBonus = dbgLevelDiff > 0
            ? Math.min(
                window.netTuning.smallerTargetBodyBonusCap || 12,
                dbgLevelDiff * (window.netTuning.smallerTargetBodyBonusPerLevel || 1.5)
              )
            : 0;
          var dbgEnemyRadius = calculateTargetRadius(window.getLevelFromInst(closestInst))
            * window.netTuning.targetRadiusScale
            + (window.netTuning.targetRadiusPadding || 0)
            + dbgBodyBonus;
          var dbgTotalRadius = myWeaponReach + dbgEnemyRadius;
          // Heuristic insets are now baked into the main trigger — recompute
          // them here for the debug HUD so the displayed trigger radius
          // matches what the autohit actually used.
          var dbgHt = window.visibleHeuristicTuning || {};
          var dbgEnemyLevel = window.getLevelFromInst(closestInst);
          var dbgTargetRelation = belsoszint > dbgEnemyLevel ? "smaller"
            : (belsoszint < dbgEnemyLevel ? "larger" : "equal");
          var dbgLevelInset = 0;
          if (belsoszint > dbgEnemyLevel) {
            var dbgDiffH = belsoszint - dbgEnemyLevel;
            dbgLevelInset = Math.min(
              dbgHt.strongerAttackerInsetCap || 24,
              dbgDiffH * (dbgHt.strongerAttackerInsetPerLevel || 8)
            );
          } else if (belsoszint < dbgEnemyLevel) {
            dbgLevelInset = dbgHt.smallerAttackerInset || 10;
          }
          var dbgContactInset = dbgTargetRelation === "smaller"
            ? (dbgHt.contactInsetVsSmallerTarget || 16)
            : (dbgTargetRelation === "larger"
                ? (dbgHt.contactInsetVsLargerTarget || 18)
                : (dbgHt.contactInsetVsEqualTarget || 16));
          var dbgBaseInset = (window.netTuning.currentDistanceInset || 0);
          var dbgReachScale = 1;
          if (window.netTuning.reachAwarePrefire) {
            var dbgRef = window.netTuning.reachPrefireReference || 250;
            var dbgMinR = window.netTuning.reachPrefireMin || 50;
            dbgReachScale = myWeaponReach < dbgRef
              ? dbgRef / Math.max(dbgMinR, myWeaponReach)
              : 1;
          }
          var dbgScaledInset = dbgBaseInset * dbgReachScale;
          var dbgHeuristicInsets = dbgLevelInset + dbgContactInset;
          var dbgTriggerRadius = Math.max(1,
            dbgTotalRadius - dbgScaledInset + dbgHeuristicInsets
          );
          if (dbgTargetRelation === "smaller") {
            var dbgCeiling = Math.max(1,
              dbgTotalRadius - (dbgHt.smallerTargetGuaranteedPenetrationInset || 26)
            );
            if (dbgTriggerRadius > dbgCeiling) dbgTriggerRadius = dbgCeiling;
          }
          var dbgDiff = closestOut.distance - dbgTriggerRadius;
          var dbgInRange = closestOut.distance <= dbgTriggerRadius;
          window.debugClosestData = {
            rawDist:        Math.round(closestOut.distance),
            adjDiff:        Math.round(dbgDiff * 10) / 10,
            enemyRadius:    Math.round(dbgEnemyRadius),
            swingState:     "Live polygon: " + myWeaponReachInfo.source,
            inputLock:      "Ignorálva",
            inTriggerRange: dbgInRange,
            dynBuffer:      Math.round(dbgBodyBonus),
            predictionMode: "Integrated — insets " + Math.round(dbgHeuristicInsets)
              + " px, relation " + dbgTargetRelation,
          };
      }
      // Housekeeping: drop stale entries so the smart-trigger map does
      // not grow without bound across long matches.
      cleanupTriggerFrames();
    }

    // Frame-synchronized main loop — hooks into the C2 engine tick
    if (window.runtime && typeof window.runtime.tick === 'function') {
      var _originalTick = window.runtime.tick;
      window.runtime.tick = function () {
        _originalTick.apply(this, arguments);
        if (window.modData.state === 'Playing') {
          try { AllLoop(); } catch (e) {}
        }
        try { drawOverlay(); } catch (e) {}
      };
      setupOverlayCanvas();
    }
  }

  var intervalId = setInterval(function checkRuntime() {
    return __awaiter(this, void 0, void 0, function () {
      function setupCustomWasm() {
        return __awaiter(this, void 0, void 0, function () {
          return __generator(this, function (_a) {
            switch (_a.label) {
              case 0:
                return [4, wasm_bindCustom()];
              case 1:
                _a.sent();
                window.wasmNet = WasmNetwork_1.new();
                window.nsg_wasmomg = adjustC_1;
                window.queueWasmClick = function(angleDeg) {
                    if (!window.wsWorker) return;
                    var token = adjustC_1(performance.now() | 0);
                    window.wsWorker.postMessage({
                        action: "send",
                        data: { a: "ps", d: { a: angleDeg, t: token } }
                    });
                };
                return [2];
            }
          });
        });
      }
      var WasmNetwork_1, get_angleC_1, adjustC_1, adapter_1, getNums_1;
      return __generator(this, function (_a) {
        switch (_a.label) {
          case 0:
            if (!window.cr_getC2Runtime) return [3, 2];
            window.runtime = window.cr_getC2Runtime();
            if (
              !(
                window.runtime &&
                window.cr &&
                window.cr.plugins_ &&
                window.cr.plugins_.NSG_PowerWS &&
                window.cr.plugins_.NSG_PowerWS.prototype.acts.Send
              )
            )
              return [3, 2];
            clearInterval(intervalId);
            ((WasmNetwork_1 = wasm_bindCustom.WasmNetwork),
              (get_angleC_1 = wasm_bindCustom.get_angleC),
              (adjustC_1 = wasm_bindCustom.adjustC),
              (adapter_1 = wasm_bindCustom.adapter),
              (getNums_1 = wasm_bindCustom.getNums));
            return [4, setupCustomWasm()];
          case 1:
            _a.sent();
            mainApp();
            _a.label = 2;
          case 2:
            return [2];
        }
      });
    });
  }, 500);
})();
