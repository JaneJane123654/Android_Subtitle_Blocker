package com.zimuzhedang.subtitleblocker.ui;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.RadialGradient;
import android.graphics.Shader;
import android.os.SystemClock;
import android.util.AttributeSet;
import android.view.View;

import androidx.annotation.Nullable;

import java.util.Random;

public final class GlowDotView extends View {
    private static final int RAY_COUNT = 72;
    private static final float TWO_PI = (float) (Math.PI * 2.0);

    private final Paint outerHaloPaint = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Paint bloomPaint = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Paint corePaint = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Paint highlightPaint = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Paint rimPaint = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Paint sparklePaint = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Paint rayPaint = new Paint(Paint.ANTI_ALIAS_FLAG);

    private final float[] rayLengthFactors = new float[RAY_COUNT];
    private final float[] rayAlphaFactors = new float[RAY_COUNT];
    private final float[] rayWidthFactors = new float[RAY_COUNT];

    private float centerX;
    private float centerY;
    private float radius;
    private float rayRotation;
    private float flickerStrength = 1.0f;
    private boolean rayTwinkleEnabled = true;

    public GlowDotView(Context context) {
        this(context, null);
    }

    public GlowDotView(Context context, @Nullable AttributeSet attrs) {
        this(context, attrs, 0);
    }

    public GlowDotView(Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        init();
    }

    private void init() {
        rayPaint.setStyle(Paint.Style.STROKE);
        rayPaint.setStrokeCap(Paint.Cap.ROUND);
        rimPaint.setStyle(Paint.Style.STROKE);
        sparklePaint.setStyle(Paint.Style.FILL);

        Random random = new Random(20260329L);
        for (int i = 0; i < RAY_COUNT; i++) {
            float sinSeed = (float) Math.sin(i * 0.73f);
            rayLengthFactors[i] = clamp(0.48f + (sinSeed * 0.16f) + (random.nextFloat() * 0.24f), 0.3f, 1.0f);
            rayAlphaFactors[i] = clamp(0.26f + random.nextFloat() * 0.74f, 0.26f, 1.0f);
            rayWidthFactors[i] = clamp(0.15f + random.nextFloat() * 0.85f, 0.15f, 1.0f);
        }
    }

    @Override
    protected void onSizeChanged(int w, int h, int oldw, int oldh) {
        super.onSizeChanged(w, h, oldw, oldh);
        centerX = w / 2f;
        centerY = h / 2f;
        radius = Math.min(w, h) / 2f;
        rebuildShaders();
    }

    @Override
    protected void onDraw(Canvas canvas) {
        super.onDraw(canvas);
        if (radius <= 0f) {
            return;
        }

        float pulse = clamp(flickerStrength, 0.76f, 1.22f);
        drawRays(canvas, pulse);

        outerHaloPaint.setAlpha(alpha(122f * pulse));
        bloomPaint.setAlpha(alpha(146f * (0.9f + pulse * 0.1f)));
        corePaint.setAlpha(alpha(228f * (0.9f + pulse * 0.1f)));
        highlightPaint.setAlpha(alpha(238f * pulse));
        rimPaint.setAlpha(alpha(95f * (0.92f + pulse * 0.08f)));
        rimPaint.setStrokeWidth(Math.max(1.2f, radius * 0.07f));

        canvas.drawCircle(centerX, centerY, radius * 1.06f, outerHaloPaint);
        canvas.drawCircle(centerX, centerY, radius * 0.9f, bloomPaint);
        canvas.drawCircle(centerX, centerY, radius * 0.62f, corePaint);
        canvas.drawCircle(centerX, centerY, radius * 0.42f, rimPaint);
        canvas.drawCircle(centerX - radius * 0.18f, centerY - radius * 0.18f, radius * 0.34f, highlightPaint);

        sparklePaint.setColor(Color.argb(alpha(172f * pulse), 245, 252, 255));
        canvas.drawCircle(centerX - radius * 0.26f, centerY - radius * 0.24f, radius * 0.08f, sparklePaint);
        sparklePaint.setColor(Color.argb(alpha(114f * pulse), 214, 242, 255));
        canvas.drawCircle(centerX + radius * 0.19f, centerY - radius * 0.16f, radius * 0.05f, sparklePaint);
    }

    public float getRayRotation() {
        return rayRotation;
    }

    public void setRayRotation(float degrees) {
        float normalized = degrees % 360f;
        if (normalized < 0f) {
            normalized += 360f;
        }
        if (Math.abs(normalized - rayRotation) < 0.01f) {
            return;
        }
        rayRotation = normalized;
        invalidate();
    }

    public float getFlickerStrength() {
        return flickerStrength;
    }

    public void setFlickerStrength(float strength) {
        float clamped = clamp(strength, 0.7f, 1.25f);
        if (Math.abs(clamped - flickerStrength) < 0.001f) {
            return;
        }
        flickerStrength = clamped;
        invalidate();
    }

    public void setRayTwinkleEnabled(boolean enabled) {
        if (rayTwinkleEnabled == enabled) {
            return;
        }
        rayTwinkleEnabled = enabled;
        invalidate();
    }

    private void rebuildShaders() {
        if (radius <= 0f) {
            return;
        }
        outerHaloPaint.setShader(new RadialGradient(
                centerX,
                centerY,
                radius,
                new int[]{
                        Color.argb(170, 130, 243, 255),
                        Color.argb(82, 95, 198, 255),
                        Color.argb(0, 95, 198, 255)
                },
                new float[]{0f, 0.62f, 1f},
                Shader.TileMode.CLAMP
        ));

        bloomPaint.setShader(new RadialGradient(
                centerX,
                centerY,
                radius * 0.96f,
                new int[]{
                        Color.argb(210, 198, 244, 255),
                        Color.argb(130, 128, 217, 255),
                        Color.argb(0, 128, 217, 255)
                },
                new float[]{0f, 0.55f, 1f},
                Shader.TileMode.CLAMP
        ));

        corePaint.setShader(new RadialGradient(
                centerX - radius * 0.08f,
                centerY - radius * 0.1f,
                radius * 0.76f,
                new int[]{
                        Color.WHITE,
                        Color.argb(255, 228, 250, 255),
                        Color.argb(230, 180, 234, 255),
                        Color.argb(68, 88, 193, 255)
                },
                new float[]{0f, 0.24f, 0.7f, 1f},
                Shader.TileMode.CLAMP
        ));

        highlightPaint.setShader(new RadialGradient(
                centerX - radius * 0.24f,
                centerY - radius * 0.24f,
                radius * 0.38f,
                new int[]{
                        Color.argb(255, 255, 255, 255),
                        Color.argb(0, 230, 246, 255)
                },
                new float[]{0f, 1f},
                Shader.TileMode.CLAMP
        ));
    }

    private void drawRays(Canvas canvas, float pulse) {
        float rotationRad = (float) Math.toRadians(rayRotation);
        float time = rayTwinkleEnabled ? SystemClock.uptimeMillis() * 0.0036f : 0f;
        float startRadius = radius * 0.42f;

        for (int i = 0; i < RAY_COUNT; i++) {
            float angle = rotationRad + (TWO_PI * i / RAY_COUNT);
            float twinkle = rayTwinkleEnabled
                    ? 0.82f + 0.18f * (float) Math.sin(time + i * 0.62f)
                    : 0.84f;
            float energy = pulse * twinkle;

            float endFactor = 0.74f + rayLengthFactors[i] * 0.26f;
            float endRadius = clamp(radius * endFactor * energy, startRadius + 1f, radius * 1.02f);

            float baseAlpha = rayTwinkleEnabled ? 50f : 36f;
            float alphaRange = rayTwinkleEnabled ? 126f : 86f;
            int rayAlpha = alpha((baseAlpha + alphaRange * rayAlphaFactors[i]) * energy);
            int r = color(158f + 20f * energy);
            int g = color(219f + 24f * energy);
            int b = color(255f);

            rayPaint.setColor(Color.argb(rayAlpha, r, g, b));
            rayPaint.setStrokeWidth(Math.max(0.8f, radius * (0.009f + 0.009f * rayWidthFactors[i])));

            float cos = (float) Math.cos(angle);
            float sin = (float) Math.sin(angle);
            float startX = centerX + cos * startRadius;
            float startY = centerY + sin * startRadius;
            float endX = centerX + cos * endRadius;
            float endY = centerY + sin * endRadius;
            canvas.drawLine(startX, startY, endX, endY, rayPaint);
        }
    }

    private static int alpha(float value) {
        return Math.max(0, Math.min(255, Math.round(value)));
    }

    private static int color(float value) {
        return Math.max(0, Math.min(255, Math.round(value)));
    }

    private static float clamp(float value, float min, float max) {
        return Math.max(min, Math.min(max, value));
    }
}
