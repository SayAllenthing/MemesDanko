using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GameSettings : MonoBehaviour
{
    public static GameSettings Instance;

    private void Awake()
    {
        Instance = this;
    }

    //Settings
    [Range(0, 10)]
    public float NinjaJumpForce = 5f;
}
