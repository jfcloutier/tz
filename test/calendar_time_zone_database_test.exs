defmodule CalendarTimeZoneDatabaseTest do
  use ExUnit.Case

  setup_all(_) do
    timezones =
      "#{
        :os.cmd(
          'cd /usr/share/zoneinfo/posix && find * -type f -or -type l | grep America | sort'
        )
      }"
      |> String.split("\n")
      |> Enum.reject(&(String.trim(&1) == ""))

    [timezones: timezones]
  end

  test "timezone period from utc iso days", %{timezones: timezones} do
    ndt_now = NaiveDateTime.local_now()

    for timezone <- timezones do
      for delta_days <- Enum.take_every(0..10000, 30) do
        delta_seconds = delta_days * 24 * 60 * 60 * -1
        ndt = NaiveDateTime.add(ndt_now, delta_seconds, :second)

        iso_days =
          Calendar.ISO.naive_datetime_to_iso_days(
            ndt.year,
            ndt.month,
            ndt.day,
            ndt.hour,
            ndt.minute,
            ndt.second,
            {0, 6}
          )

        case Tz.TimeZoneDatabase.time_zone_period_from_utc_iso_days(iso_days, timezone) do
          {:ok,
           %{
             std_offset: std_offset,
             utc_offset: utc_offset,
             zone_abbr: abbr
           }} ->
            # assuming largest std offset i 1 hour
            assert abs(std_offset) in 0..(60 * 60)
            # largest utc offset is 14 hours
            assert abs(utc_offset) in 0..(14 * 60 * 60)
            assert is_binary(abbr)

          {:error, :time_zone_not_found} ->
            IO.puts("Time zone not found #{timezone}")
            assert false
        end
      end
    end
  end

  test "timezone period from wall date time", %{timezones: timezones} do
    ndt_now = NaiveDateTime.local_now()

    for timezone <- timezones do
      for delta_days <- Enum.take_every(0..10000, 30) do
        delta_seconds = delta_days * 24 * 60 * 60 * -1
        ndt = NaiveDateTime.add(ndt_now, delta_seconds, :second)

        case Tz.TimeZoneDatabase.time_zone_periods_from_wall_datetime(ndt, timezone) do
          {:ok,
           %{
             std_offset: std_offset,
             utc_offset: utc_offset,
             zone_abbr: abbr
           }} ->
            # assuming largest std offset i 1 hour
            assert abs(std_offset) in 0..(60 * 60)
            # largest utc offset is 14 hours
            assert abs(utc_offset) in 0..(14 * 60 * 60)
            assert is_binary(abbr)

          {:error, :time_zone_not_found} ->
            IO.puts("Time zone not found #{timezone}")
            assert false
        end
      end
    end
  end
end
