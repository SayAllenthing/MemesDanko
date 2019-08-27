using System;

[System.Flags]
public enum MovementState
{
    None = 0,
    LockedByAnimation = 1,
    LockedByState = 2,
    LockedByDeath = 3,
    LockedByActiveSkill = 4,
    LockedByPause = 5,
    LockedByForce = 6
}

public class MovementFlags
{
    MovementState State;

    public void SetFlag(MovementState flag)
    {
        State |= flag;
    }

    public void ClearFlag(MovementState flag)
    {
        State &= ~flag;
    }

    public bool HasFlag(MovementState flag)
    {
        return State.HasFlag(flag);
    }

    public bool Equals(MovementState flag)
    {
        return State == flag;
    }
}
