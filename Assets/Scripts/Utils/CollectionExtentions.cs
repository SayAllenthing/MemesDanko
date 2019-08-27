using UnityEngine;
using System.Collections.Generic;

public static class CollectionExtension
{

    public static T RandomElement<T>(this IList<T> list)
    {
        return list[Random.Range(0,list.Count)];
    }

    public static T RandomElement<T>(this T[] array)
    {
        return array[Random.Range(0,array.Length)];
    }
}