-- BK98_DRIFT class
BK98_DRIFT = {}
setmetatable(BK98_DRIFT, {
  __index = function(table, key)
    if BK98_CONSTANTS[key] then return BK98_CONSTANTS[key] end
    error("Unknown field or method: " .. tostring(key), 2)
  end,
})

-- Initialize the BK98_DRIFT object
function BK98_DRIFT:new()
  local instance = {
    fontHeight = GetRenderedCharacterHeight(0.5, BK98_CONSTANTS.font),
    lastRecord = 0,
    point = 0,
    idleTime = 0,
    multiplayer = 0,
    cancelTime = 0,
  }

  setmetatable(instance, self)
  self.__index = self
  return instance
end

-- Function to cancel drift recording
function BK98_DRIFT:cancelDrift(vehicle)
  if DoesEntityExist(vehicle) then SetVehicleCheatPowerIncrease(vehicle, 1.0) end
  self.lastRecord = self.point > self.lastRecord and self.point or self.lastRecord
  self.point = 0
end

-- Function to check if drift should be cancelled
function BK98_DRIFT:shouldCancelDrift(playerPed, vehicle)
  return not DoesEntityExist(playerPed) or
      not DoesEntityExist(vehicle) or
      IsPauseMenuActive() or
      GetPedInVehicleSeat(vehicle, -1) ~= playerPed or
      GetEntitySpeed(playerPed) < self.ninSpeed
end

-- Function to calculate the drift angle
function BK98_DRIFT:calculateDriftAngle(veh)
  if not veh then return 0, 0 end

  local vel = GetEntityVelocity(veh)
  local vx, vy = vel.x, vel.y
  local modV = math.sqrt(vx * vx + vy * vy)

  local rot = GetEntityRotation(veh, 0)
  local rz = rot.z
  local sn, cs = -math.sin(math.rad(rz)), math.cos(math.rad(rz))

  if GetEntitySpeed(veh) > self.maxSpeed or GetVehicleCurrentGear(veh) == 0 then return 0, modV end

  local cosX = (sn * vx + cs * vy) / modV
  if cosX >= 0.966 or cosX <= 0 then return 0, modV end
  return math.deg(math.acos(cosX)) * 0.5, modV
end

-- Function to draw HUD text
function BK98_DRIFT:drawHUDText(text, color, coordsX, coordsY, scale, textJustification, coordsXTextJustification)
  SetTextFont(self.font)
  SetTextScale(0.0, scale)
  ---local r, g, b, a = table.unpack(color)
  local r, g, b, a = color[1], color[2], color[3], color[4]
  SetTextColour(r, g, b, a)

  SetTextDropshadow(0, 0, 0, 0, a)
  SetTextEdge(1, 0, 0, 0, a)

  if textJustification and coordsXTextJustification then
    SetTextWrap(coordsX, coordsXTextJustification)
    SetTextJustification(textJustification or 0)
  end

  SetTextDropShadow()
  SetTextOutline()

  BeginTextCommandDisplayText("STRING")
  AddTextComponentSubstringPlayerName(text)
  EndTextCommandDisplayText(coordsX, coordsY)
end

-- Function to group digits with spaces
function BK98_DRIFT:groupDigits(value)
  return tostring(value):gsub('(%d%d%d)(%d+)', '%1 %2')
end

-- Function to round a number
function BK98_DRIFT:roundNumber(number)
  local num = tonumber(number) or 0
  return math.floor(math.max(0, math.min(num, 999999999)))
end

-- Function to determine multiplayer multiplier
function BK98_DRIFT:getMultiplier(score)
  local maxMultiplier = 1
  for _, threshold in ipairs(self.multiplier) do
    if score >= threshold then
      maxMultiplier = maxMultiplier + 1
    end
  end
  return maxMultiplier
end

-- Function to calculate bonus points
function BK98_DRIFT:calculateBonusPoints(previous)
  local points = self:roundNumber(previous)
  return (points or 0)
end

-- Function to handle drift counting
function BK98_DRIFT:driftCount(GameTime, PlayerVeh, prev_dmg, idleTime, total, score, multiplayer, fail, curAlpha,
                               screenScore, addTime)
  if IsVehicleOnAllWheels(PlayerVeh) then
    local angle, velocity = self:calculateDriftAngle(PlayerVeh)
    self:drawBarForCurrentAngle(angle)
    local tempBool = (GameTime - idleTime < 550)

    if fail > GameTime then
      angle = 0
      score = 0
      multiplayer = 1
      prev_dmg = GetVehicleBodyHealth(PlayerVeh)
    end

    if GetVehicleBodyHealth(PlayerVeh) ~= prev_dmg then
      prev_dmg = GetVehicleBodyHealth(PlayerVeh)
      tempBool = false
      angle = 0
      screenScore = self:calculateBonusPoints(score) * multiplayer
      multiplayer = 1
      fail = GameTime + 1200
      score = 0
    elseif not tempBool and score ~= 0 then
      total = total + self:calculateBonusPoints(score) * multiplayer
      score = 0
    end

    if angle ~= 0 and fail <= GameTime and addTime <= GameTime then
      local callMultiplayer = self:getMultiplier(score)
      multiplayer = (callMultiplayer > multiplayer and callMultiplayer or multiplayer)
      if tempBool then
        score = score + math.floor(angle * velocity) * 0.15
      else
        score = math.floor(angle * velocity) * 0.15
      end
      screenScore = self:calculateBonusPoints(score)

      idleTime = GameTime
      addTime = GameTime + 40 -- 25 FPS count
    end
  end

  if GameTime - idleTime < 500 then
    curAlpha = math.min(255, curAlpha + 10)
  else
    curAlpha = math.max(0, curAlpha - 10)
  end

  if fail >= GameTime then
    if screenScore > 0 then
      self:drawHUDText(string.format("\n%s", tostring(self:groupDigits(math.floor(screenScore)))), self.RED,
        0.5, 0.8, self.displayIndicatorY, 0, 1.0)
    end
  else
    self:drawHUDText(string.format("\n+%s x%i", tostring(self:groupDigits(screenScore)), math.floor(multiplayer)),
      { self.ORANGE[1], self.ORANGE[2], self.ORANGE[3], curAlpha }, 0.5, 0.8, self.displayIndicatorY, 0, 1.0)
  end
  return prev_dmg, idleTime, total, score, multiplayer, fail, curAlpha, screenScore, addTime
end

-- Function to draw bar for current angle
function BK98_DRIFT:drawBarForCurrentAngle(angle)
  local angleText = string.format("%.2f°", angle)

  -- Draw bar to show current angle
  local barWidth = 0.3
  local barHeight = 0.005
  local xMid = 0.5
  local yMid = self.displayIndicatorY
  local fontHeight = self.fontHeight
  local textXOffset = (barWidth / 2)
  local barHeight05 = barHeight / 2
  local xMidAndTextXOffset = xMid + textXOffset
  local xMidTextXOffset = xMid - textXOffset
  local yMidBarHeightFontHeight = yMid - barHeight - fontHeight

  self:drawHUDText(angleText, self.WHITE, xMid, yMid, 0.5, 0, xMidAndTextXOffset)

  self:drawHUDText("CURRENT", self.ORANGE, xMidTextXOffset, yMid, 0.3, 1,
    xMidAndTextXOffset)
  self:drawHUDText(self:groupDigits(self.point), self.ORANGE, xMidTextXOffset, yMid + fontHeight / 2, 0.4, 1,
    xMidAndTextXOffset)

  self:drawHUDText("BEST", self.WHITE, xMidTextXOffset, yMid, 0.3, 2,
    xMidAndTextXOffset)
  self:drawHUDText(self:groupDigits(self.lastRecord), self.WHITE, xMidTextXOffset, yMid + fontHeight / 2, 0.4,
    2,
    xMidAndTextXOffset)

  self:drawHUDText("X " .. (self.multiplayer), self.WHITE, xMidTextXOffset, yMidBarHeightFontHeight, 0.5,
    2, xMidAndTextXOffset)

  local toFailTime = ((self.maxIdleTime - (GetGameTimer() - self.idleTime)) / 1000)
  if (toFailTime < 3.0) then
    self:drawHUDText((string.format("%.1fs.", toFailTime)),
      self.WHITE, xMidTextXOffset, yMidBarHeightFontHeight, 0.5, 1, xMidAndTextXOffset)
  end

  DrawRect(xMid, yMid - barHeight05, barWidth, barHeight, 255, 255, 255, 255)
  DrawRect(xMid, yMid - barHeight05, barWidth / 100, barHeight, 255, 0, 0, 64)
  DrawRect(xMid, yMid - barHeight05, 0.25 * (angle / 90), barHeight, 0, 0, 255, 128)
end

-- Function to initialize drift recording
function BK98_DRIFT:initializeDrift(playerPed, vehicle)
  if self:shouldCancelDrift(playerPed, vehicle) then
    self:cancelDrift(vehicle)
    return
  end

  local angle, _ = self:calculateDriftAngle(vehicle)
  if angle == 0 then
    self:cancelDrift(vehicle)
    return
  end

  self.point = 0

  local prevDamage = GetVehicleBodyHealth(vehicle)
  self.idleTime = GetGameTimer()
  local score = 0
  self.multiplayer = 1
  local failTime = 0
  local currentAlpha = 0
  local screenScore = 0
  local addTime = 0

  local cancelTest = GetGameTimer() + 1000

  while true do
    local currentTime = GetGameTimer()
    if (self.powerIncrease > 0 and screenScore > 0) then SetVehicleCheatPowerIncrease(vehicle, self.powerIncrease) end
    if (currentTime > cancelTest) then
      if self:shouldCancelDrift(playerPed, vehicle) then
        self:cancelDrift(vehicle)
        return
      end
      cancelTest = currentTime + 1000
    end

    prevDamage, self.idleTime, self.point, score, self.multiplayer, failTime, currentAlpha, screenScore, addTime =
        self:driftCount(currentTime, vehicle, prevDamage, self.idleTime, self.point, score, self.multiplayer, failTime,
          currentAlpha,
          screenScore, addTime)

    if (currentTime - self.idleTime) > self.maxIdleTime then
      if (self.multiplayer <= 1) then
        self:cancelDrift(vehicle)
        return
      end
      self.multiplayer = self.multiplayer - 1
      self.idleTime = currentTime
      screenScore = 0
    end

    Citizen.Wait(0)
  end
end

-- Main loop to monitor player's vehicle and initiate drift recording
Citizen.CreateThread(function()
  local bk98Drift = BK98_DRIFT:new()
  while true do
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    if vehicle and GetPedInVehicleSeat(vehicle, -1) == playerPed then
      bk98Drift:initializeDrift(playerPed, vehicle)
    end
    Citizen.Wait(100)
  end
end)
