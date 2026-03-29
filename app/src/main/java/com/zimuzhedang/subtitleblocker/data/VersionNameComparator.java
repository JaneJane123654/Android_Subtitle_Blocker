package com.zimuzhedang.subtitleblocker.data;

import java.util.ArrayList;
import java.util.List;

/**
 * 版本号比较工具。
 */
public final class VersionNameComparator {
    private VersionNameComparator() {
    }

    public static boolean isNewer(String candidate, String baseline) {
        return compare(candidate, baseline) > 0;
    }

    public static int compare(String leftRaw, String rightRaw) {
        String left = normalize(leftRaw);
        String right = normalize(rightRaw);
        List<Integer> leftParts = toParts(left);
        List<Integer> rightParts = toParts(right);
        int size = Math.max(leftParts.size(), rightParts.size());
        for (int i = 0; i < size; i++) {
            int lv = i < leftParts.size() ? leftParts.get(i) : 0;
            int rv = i < rightParts.size() ? rightParts.get(i) : 0;
            if (lv != rv) {
                return lv > rv ? 1 : -1;
            }
        }
        return 0;
    }

    public static String normalize(String raw) {
        if (raw == null) {
            return "0";
        }
        String value = raw.trim();
        while (!value.isEmpty() && !Character.isDigit(value.charAt(0))) {
            value = value.substring(1);
        }
        if (value.isEmpty()) {
            return "0";
        }
        int qualifierStart = value.length();
        int dashIndex = value.indexOf('-');
        int plusIndex = value.indexOf('+');
        if (dashIndex >= 0) {
            qualifierStart = Math.min(qualifierStart, dashIndex);
        }
        if (plusIndex >= 0) {
            qualifierStart = Math.min(qualifierStart, plusIndex);
        }
        String core = value.substring(0, qualifierStart);
        return core.isEmpty() ? "0" : core;
    }

    private static List<Integer> toParts(String normalized) {
        List<Integer> parts = new ArrayList<>();
        String[] blocks = normalized.split("\\.");
        for (String block : blocks) {
            if (block == null || block.isEmpty()) {
                parts.add(0);
                continue;
            }
            String digits = block.replaceAll("[^0-9]", "");
            if (digits.isEmpty()) {
                parts.add(0);
            } else {
                try {
                    parts.add(Integer.parseInt(digits));
                } catch (NumberFormatException e) {
                    parts.add(0);
                }
            }
        }
        if (parts.isEmpty()) {
            parts.add(0);
        }
        return parts;
    }
}
