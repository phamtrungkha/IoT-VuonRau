package com.vuonrau.service;

import com.vuonrau.config.DeviceProperties;
import com.vuonrau.dto.HistoryTimelineItem;
import com.vuonrau.dto.HistoryTimelineResponse;
import com.vuonrau.exception.UnknownDeviceException;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

@Service
public class DeviceHistoryService {

    public static final int PAGE_SIZE = 300;
    private static final Duration MAX_SPAN = Duration.ofDays(3);

    private static final String HUMIDITY_SQL =
            "SELECT sr.captured_at AS evt_at, 'humidity' AS kind, sr.value_int AS humidity_raw, "
                    + "CAST(NULL AS SIGNED) AS valve_on FROM sensor_readings sr "
                    + "INNER JOIN sensor_types st ON st.id = sr.sensor_type_id AND st.code = 'humidity_raw' "
                    + "WHERE sr.device_id = ? AND sr.captured_at >= ? AND sr.captured_at <= ?";

    private static final String VALVE_SQL =
            "SELECT wve.recorded_at AS evt_at, 'valve' AS kind, CAST(NULL AS SIGNED) AS humidity_raw, "
                    + "wve.on_state AS valve_on FROM water_valve_events wve "
                    + "WHERE wve.device_id = ? AND wve.recorded_at >= ? AND wve.recorded_at <= ?";

    private final JdbcTemplate jdbcTemplate;
    private final DeviceProperties deviceProperties;

    public DeviceHistoryService(JdbcTemplate jdbcTemplate, DeviceProperties deviceProperties) {
        this.jdbcTemplate = jdbcTemplate;
        this.deviceProperties = deviceProperties;
    }

    public HistoryTimelineResponse loadTimeline(
            String deviceId,
            Instant from,
            Instant to,
            boolean humidity,
            boolean valve,
            long offset) {
        if (!deviceProperties.isAllowed(deviceId)) {
            throw new UnknownDeviceException();
        }
        if (from.isAfter(to)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "from must not be after to");
        }
        if (Duration.between(from, to).compareTo(MAX_SPAN) > 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Range must be at most 3 days");
        }
        if (offset < 0 || offset % PAGE_SIZE != 0) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "offset must be a non-negative multiple of " + PAGE_SIZE);
        }

        if (!humidity && !valve) {
            return new HistoryTimelineResponse(List.of(), false);
        }

        Timestamp fromTs = Timestamp.from(from);
        Timestamp toTs = Timestamp.from(to);

        var unions = new ArrayList<String>();
        var args = new ArrayList<Object>();

        if (humidity) {
            unions.add(HUMIDITY_SQL);
            args.add(deviceId);
            args.add(fromTs);
            args.add(toTs);
        }
        if (valve) {
            unions.add(VALVE_SQL);
            args.add(deviceId);
            args.add(fromTs);
            args.add(toTs);
        }

        String inner = String.join(" UNION ALL ", unions);
        String sql = "SELECT * FROM (" + inner + ") u ORDER BY evt_at DESC LIMIT ? OFFSET ?";
        args.add(PAGE_SIZE + 1);
        args.add(offset);

        List<HistoryTimelineItem> rows =
                jdbcTemplate.query(sql, (rs, rowNum) -> mapRow(rs), args.toArray());

        boolean hasMore = rows.size() > PAGE_SIZE;
        List<HistoryTimelineItem> page = hasMore ? rows.subList(0, PAGE_SIZE) : rows;
        return new HistoryTimelineResponse(page, hasMore);
    }

    private static HistoryTimelineItem mapRow(ResultSet rs) throws SQLException {
        Instant at = rs.getTimestamp("evt_at").toInstant();
        String kind = rs.getString("kind");
        if ("humidity".equals(kind)) {
            long raw = rs.getLong("humidity_raw");
            Integer humidityRaw = rs.wasNull() ? null : (int) raw;
            return new HistoryTimelineItem(at, kind, humidityRaw, null);
        }
        if ("valve".equals(kind)) {
            boolean on = rs.getInt("valve_on") != 0;
            return new HistoryTimelineItem(at, kind, null, on ? "ON" : "OFF");
        }
        throw new IllegalStateException("Unknown timeline kind: " + kind);
    }
}
