function random_color()
  return math.random(0, 255), math.random(0, 255), math.random(0, 255)
end

function set_track_color(track)
  local r, g, b = random_color()
  local color = reaper.ColorToNative(r, g, b) | 0x1000000
  reaper.SetTrackColor(track, color)
end

function main()
  local track_count = reaper.CountTracks(0)
  for i = 0, track_count - 1 do
    local track = reaper.GetTrack(0, i)
    set_track_color(track)
  end
end

main()
