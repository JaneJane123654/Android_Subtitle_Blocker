package com.zimuzhedang.subtitleblocker.data;

import org.junit.Assert;
import org.junit.Test;

public final class VersionNameComparatorTest {

    @Test
    public void compare_handlesPrefixAndSegments() {
        Assert.assertTrue(VersionNameComparator.compare("v1.0.1", "1.0.0") > 0);
        Assert.assertTrue(VersionNameComparator.compare("1.2", "1.2.0") == 0);
        Assert.assertTrue(VersionNameComparator.compare("2.0.0", "1.9.9") > 0);
        Assert.assertTrue(VersionNameComparator.compare("1.0.0", "1.0.1") < 0);
    }

    @Test
    public void normalize_removesQualifier() {
        Assert.assertEquals("1.3.2", VersionNameComparator.normalize("v1.3.2-beta+12"));
        Assert.assertEquals("0", VersionNameComparator.normalize(""));
    }
}
