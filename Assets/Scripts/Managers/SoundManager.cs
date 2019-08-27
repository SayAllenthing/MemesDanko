using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SoundManager : MonoBehaviour
{
    const float kMusicMax = 1f;
    const float kUIMax = 1f;

    public static SoundManager Instance;

    public float MasterVolume = 1;

    public float MusicVolume = 0;
    public float SFXVolume = 1; 

    private void Awake()
    {
        Instance = this;
    }

    public AudioSource MusicSource;
    public AudioSource SfxSource;
    public AudioSource UISource;

    public void PlaySfx(AudioClip clip)
    {
        SfxSource.clip = clip;
        SfxSource.volume = SFXVolume * MasterVolume;
        SfxSource.Play();
    }

    public void PlayUI(AudioClip clip)
    {
        UISource.clip = clip;
        UISource.volume = SFXVolume * MasterVolume * kUIMax;
        UISource.Play();
    }

    public void PlayMusic(AudioClip music, bool loop = true)
    {
        StopMusic(0f);

        MusicSource.volume = MusicVolume * kMusicMax * MasterVolume;
        MusicSource.clip = music;
        MusicSource.loop = loop;
        MusicSource.PlayDelayed(0.2f);
    }

    public void StopMusic(float fadeOut = 0.5f)
    {
        StartCoroutine(FadeOutMusic(fadeOut));
    }

    public void SwitchMusic(AudioClip music, bool loop = true)
    {
        StopAllCoroutines();
        StartCoroutine(FadeOutMusic(1f, music, loop));
    }

    IEnumerator FadeOutMusic(float time = 0.5f, AudioClip nextMusic = null, bool loopNext = true)
    {
        float startTime = Time.time;
        float endTime = startTime + time;

        float startVolume = MusicSource.volume;

        while(Time.time < endTime)
        {
            float t = Mathf.InverseLerp(startTime, endTime, Time.time);
            MusicSource.volume = Mathf.Lerp(startVolume, 0, t);

            yield return new WaitForEndOfFrame();
        }

        MusicSource.volume = 0;
        MusicSource.Stop();

        if(nextMusic != null)
        {
            PlayMusic(nextMusic, loopNext);
        }

        yield return null;
    }
}
