local Keys = { ["W"] = 32, ["A"] = 34, ["S"] = 8, ["D"] = 9 }

Citizen.CreateThread(function()
    local handsup = false
    local previousWeapon = -1569615261
    local timeup = 0

    while true do
        Citizen.Wait(0)
        local lPed = GetPlayerPed(-1)
        RequestAnimDict("random@mugging3")
        RequestAnimDict("random@arrests")
        RequestAnimDict("random@arrests@busted")
        RequestAnimDict("mp_weapon_drop")

        if IsControlPressed(1, 323)
            and not IsPedInAnyVehicle(lPed, true)
            and not IsEntityInWater(lPed)
            and not IsEntityPlayingAnim( lPed, "random@arrests", "idle_2_hands_up", 3 ) 
            and not IsEntityPlayingAnim( lPed, "random@arrests", "kneeling_arrest_idle", 3 ) 
            and not IsEntityPlayingAnim( lPed, "random@arrests@busted", "enter", 3 ) 
            and not IsEntityPlayingAnim( lPed, "random@arrests@busted", "idle_a", 3 ) then
            
            if DoesEntityExist(lPed) then
                Citizen.CreateThread(function()
                    RequestAnimDict("random@mugging3")
                    while not HasAnimDictLoaded("random@mugging3") do
                        Citizen.Wait(100)
                    end

                    if not handsup and not IsEntityPlayingAnim(lPed, "mp_arresting", "idle", 3) then
                        handsup = true
                        previousWeapon = GetSelectedPedWeapon(GetPlayerPed(-1))
                        SetEnableHandcuffs(lPed, true)
                        SetCurrentPedWeapon(lPed, GetHashKey("WEAPON_UNARMED"), true)
                        TaskPlayAnim(lPed, "random@mugging3", "handsup_standing_base", 8.0, -8, -1, 49, 0, 0, 0, 0)
                    end

                    timeup = timeup + 1
                    if timeup > 100 then
                        ClearPedSecondaryTask(lPed)
                        TaskPlayAnim( lPed, "random@arrests", "idle_2_hands_up", 8.0, 1.0, -1, 2, 0, 0, 0, 0 )
                        Citizen.Wait (4000)
                        TaskPlayAnim( lPed, "random@arrests", "kneeling_arrest_idle", 8.0, 1.0, -1, 2, 0, 0, 0, 0 )
                        Citizen.Wait (500)
                        TaskPlayAnim( lPed, "random@arrests@busted", "enter", 8.0, 1.0, -1, 2, 0, 0, 0, 0 )
                        Citizen.Wait (1000)
                        TaskPlayAnim( lPed, "random@arrests@busted", "idle_a", 8.0, 1.0, -1, 9, 0, 0, 0, 0 )
                    end
                end)
            end
        end

        if not IsPedInAnyVehicle(lPed, true) and (IsControlJustReleased(1, 323) or (timeup > 100 and (IsControlPressed(1, Keys['W']) or IsControlPressed(1, Keys['A']) or IsControlPressed(1, Keys['S']) or IsControlPressed(1, Keys['D'])))) then
            if DoesEntityExist(lPed) then
                Citizen.CreateThread(function()
                    RequestAnimDict("random@mugging3")
                    while not HasAnimDictLoaded("random@mugging3") do
                        Citizen.Wait(100)
                    end

                    if handsup then
                        handsup = false
                        timeup = 0
                        SetEnableHandcuffs(lPed, false)
                        ClearPedSecondaryTask(lPed)
                        SetCurrentPedWeapon(lPed, previousWeapon, true)
                    end

                    if (IsEntityPlayingAnim( lPed, "random@arrests@busted", "idle_a", 3 )) then 
                        TaskPlayAnim( lPed, "random@arrests@busted", "exit", 8.0, 1.0, -1, 2, 0, 0, 0, 0 )
                        Citizen.Wait (3000)
                        TaskPlayAnim( lPed, "random@arrests", "kneeling_arrest_get_up", 8.0, 1.0, -1, 128, 0, 0, 0, 0 )
                    end
                end)
            end
        end
    end
end)

local mp_pointing = false
local keyPressed = false

local function startPointing()
    local ped = GetPlayerPed(-1)
    RequestAnimDict("anim@mp_point")
    while not HasAnimDictLoaded("anim@mp_point") do
        Wait(0)
    end
    SetPedCurrentWeaponVisible(ped, 0, 1, 1, 1)
    SetPedConfigFlag(ped, 36, 1)
    Citizen.InvokeNative(0x2D537BA194896636, ped, "task_mp_pointing", 0.5, 0, "anim@mp_point", 24)
    RemoveAnimDict("anim@mp_point")
end

local function stopPointing()
    local ped = GetPlayerPed(-1)
    Citizen.InvokeNative(0xD01015C7316AE176, ped, "Stop")
    if not IsPedInjured(ped) then
        ClearPedSecondaryTask(ped)
    end
    if not IsPedInAnyVehicle(ped, 1) then
        SetPedCurrentWeaponVisible(ped, 1, 1, 1, 1)
    end
    SetPedConfigFlag(ped, 36, 0)
    ClearPedSecondaryTask(PlayerPedId())
end

local once = true
local oldval = false
local oldvalped = false

Citizen.CreateThread(function()
    while true do
        Wait(0)

        if once then
            once = false
        end

        if not keyPressed then
            if IsControlPressed(0, 29) and not mp_pointing and IsPedOnFoot(PlayerPedId()) and not IsEntityPlayingAnim(GetPlayerPed(-1), "mp_arresting", "idle", 3) then
                Wait(200)
                if not IsControlPressed(0, 29) then
                    keyPressed = true
                    startPointing()
                    mp_pointing = true
                else
                    keyPressed = true
                    while IsControlPressed(0, 29) do
                        Wait(50)
                    end
                end
            elseif (IsControlPressed(0, 29) and mp_pointing) or (not IsPedOnFoot(PlayerPedId()) and mp_pointing) then
                keyPressed = true
                mp_pointing = false
                stopPointing()
            end
        end

        if keyPressed then
            if not IsControlPressed(0, 29) then
                keyPressed = false
            end
        end

        -- stop pointing when cuffed
        if IsEntityPlayingAnim(GetPlayerPed(-1), "mp_arresting", "idle", 3) and mp_pointing then
            mp_pointing = false
            stopPointing()
        end
        
        if Citizen.InvokeNative(0x921CE12C489C4C41, PlayerPedId()) and not mp_pointing then
            stopPointing()
        end

        if Citizen.InvokeNative(0x921CE12C489C4C41, PlayerPedId()) then
            if not IsPedOnFoot(PlayerPedId()) then
                stopPointing()
            else
                local ped = GetPlayerPed(-1)
                local camPitch = GetGameplayCamRelativePitch()
                if camPitch < -70.0 then
                    camPitch = -70.0
                elseif camPitch > 42.0 then
                    camPitch = 42.0
                end
                camPitch = (camPitch + 70.0) / 112.0

                local camHeading = GetGameplayCamRelativeHeading()
                local cosCamHeading = Cos(camHeading)
                local sinCamHeading = Sin(camHeading)
                if camHeading < -180.0 then
                    camHeading = -180.0
                elseif camHeading > 180.0 then
                    camHeading = 180.0
                end
                camHeading = (camHeading + 180.0) / 360.0

                local blocked = 0
                local nn = 0

                local coords = GetOffsetFromEntityInWorldCoords(ped, (cosCamHeading * -0.2) - (sinCamHeading * (0.4 * camHeading + 0.3)), (sinCamHeading * -0.2) + (cosCamHeading * (0.4 * camHeading + 0.3)), 0.6)
                local ray = Cast_3dRayPointToPoint(coords.x, coords.y, coords.z - 0.2, coords.x, coords.y, coords.z + 0.2, 0.4, 95, ped, 7);
                nn,blocked,coords,coords = GetRaycastResult(ray)

                Citizen.InvokeNative(0xD5BB4025AE449A4E, ped, "Pitch", camPitch)
                Citizen.InvokeNative(0xD5BB4025AE449A4E, ped, "Heading", camHeading * -1.0 + 1.0)
                Citizen.InvokeNative(0xB0A6CFD2C69C1088, ped, "isBlocked", blocked)
                Citizen.InvokeNative(0xB0A6CFD2C69C1088, ped, "isFirstPerson", Citizen.InvokeNative(0xEE778F8C7E1142E2, Citizen.InvokeNative(0x19CAFA3C87F7C2FF)) == 4)

            end
        end
    end
end)