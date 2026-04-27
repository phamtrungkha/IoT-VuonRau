/**
 * VuonRau - Public IP registry (GAS Web App)
 *
 * - POST: cập nhật IP mới nhất
 * - GET: đọc IP mới nhất dạng JSON
 *
 * Bảo mật tối thiểu bằng shared secret `key`.
 */

const SECRET_KEY = 'vuonrauiotip';

const PROP_IP = 'latestIp.ip';
const PROP_UPDATED_AT = 'latestIp.updatedAt'; // epoch ms
const PROP_META = 'latestIp.meta'; // JSON string (optional)

function doGet(e) {
  const ok = _checkKey(e);
  if (!ok) return _json({ ok: false, error: 'unauthorized' }, 401);

  const props = PropertiesService.getScriptProperties();
  const ip = props.getProperty(PROP_IP) || '';
  const updatedAtStr = props.getProperty(PROP_UPDATED_AT) || '';
  const updatedAt = updatedAtStr ? Number(updatedAtStr) : null;

  return _json({
    ok: true,
    ip: ip,
    updatedAt: updatedAt,
  });
}

function doPost(e) {
  const ok = _checkKey(e);
  if (!ok) return _json({ ok: false, error: 'unauthorized' }, 401);

  let body = {};
  try {
    body = JSON.parse((e && e.postData && e.postData.contents) || '{}');
  } catch (err) {
    return _json({ ok: false, error: 'invalid_json' }, 400);
  }

  const ip = String(body.ip || '').trim();
  if (!_isValidIp(ip)) {
    return _json({ ok: false, error: 'invalid_ip' }, 400);
  }

  const now = Date.now();
  const props = PropertiesService.getScriptProperties();
  props.setProperty(PROP_IP, ip);
  props.setProperty(PROP_UPDATED_AT, String(now));

  // Optional metadata (host/source/sentAt...) để debug
  const meta = {
    source: body.source || null,
    host: body.host || null,
    sentAt: body.sentAt || null,
    userAgent: (e && e.headers && e.headers['User-Agent']) || null,
  };
  props.setProperty(PROP_META, JSON.stringify(meta));

  return _json({ ok: true, ip: ip, updatedAt: now });
}

function _checkKey(e) {
  const key = (e && e.parameter && e.parameter.key) ? String(e.parameter.key) : '';
  return key && key === SECRET_KEY;
}

function _isValidIpv4(ip) {
  if (!ip) return false;
  const m = ip.match(/^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/);
  if (!m) return false;
  for (let i = 1; i <= 4; i++) {
    const n = Number(m[i]);
    if (!Number.isFinite(n) || n < 0 || n > 255) return false;
  }
  return true;
}

function _isValidIpv6(ip) {
  if (!ip) return false;
  // Validate ở mức thực dụng (không cần RFC-perfect):
  // - chỉ hex, ':' và có ít nhất 1 dấu ':'
  // - không có ký tự lạ
  // - không có quá 8 nhóm (bỏ qua các case quá dị)
  if (!/^[0-9A-Fa-f:]+$/.test(ip)) return false;
  if (ip.indexOf(':') === -1) return false;
  const groups = ip.split(':');
  if (groups.length > 8 + 1) return false; // cho phép có '::' tạo group rỗng
  return true;
}

function _isValidIp(ip) {
  return _isValidIpv6(ip) || _isValidIpv4(ip);
}

function _json(obj, statusCode) {
  const out = ContentService
    .createTextOutput(JSON.stringify(obj))
    .setMimeType(ContentService.MimeType.JSON);

  // setStatusCode có thể không luôn được hỗ trợ trong mọi runtime; vẫn trả body có `ok:false`
  if (typeof out.setStatusCode === 'function' && statusCode) {
    out.setStatusCode(statusCode);
  }
  return out;
}
