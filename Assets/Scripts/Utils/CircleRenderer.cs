using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(LineRenderer))]
public class CircleRenderer : MonoBehaviour
{

    public int segments;
    [Range(0, 1)]
    public float arcFraction = 1f;
    public float radius = .10f;

    [Range(0, 1)]
    public float Fold = 1;

    int segmentsLastFrame;
    float radiusLastFrame;
    float arcFractionLastFrame;
    float FoldLastFrame;
    LineRenderer line;

    void Start()
    {
        line = GetComponent<LineRenderer>();
        DrawCircle(segments);
    }

    void LateUpdate()
    {
        if (Changed() && segments > 0)
        {
            DrawCircle(segments);
        }
        segmentsLastFrame = segments;
        radiusLastFrame = radius;
        arcFractionLastFrame = arcFraction;
        FoldLastFrame = Fold;        
    }

    bool Changed()
    {
        return segments != segmentsLastFrame || radius != radiusLastFrame || arcFraction != arcFractionLastFrame || Fold != FoldLastFrame;
    }

    void DrawCircle(int segments)
    {
        Vector3[] points = new Vector3[segments];
        int actualSegments = (int)((float)segments * arcFraction);
        line.positionCount = actualSegments;
        for (int i = 0; i < actualSegments; i++)
        {
            float angle = ((float)i / segments) * Mathf.PI * 2.0f;

            Vector3 StraightVector = -transform.right * ((float)i / segments) * Mathf.PI * 2.0f * radius;
            Vector3 CircleVector = new Vector3(Mathf.Sin(angle) * radius, Mathf.Cos(angle) * radius, 0);
            points[i] = Vector3.Lerp(StraightVector, CircleVector, Fold);
        }
        line.SetPositions(points);
    }
}