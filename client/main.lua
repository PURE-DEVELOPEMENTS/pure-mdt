local RSGCore = exports['rsg-core']:GetCoreObject()

local function FormatDate(dateString)
    if not dateString then return "N/A" end
    
    local year, month, day, hour, minute = string.match(dateString, "(%d+)-(%d+)-(%d+) (%d+):(%d+)")
    if not year then return dateString end
    
    return string.format("%s/%s/%s %s:%s", day, month, year, hour, minute)
end

-- Function to get currently equipped weapon
function GetEquippedWeapon()
    local playerPed = PlayerPedId()
    local success, weaponHash = GetCurrentPedWeapon(playerPed)
    local Player = RSGCore.Functions.GetPlayerData()
    local inventory = Player.items
    
    if Config.Debug then
        print('Current weapon hash:', weaponHash)
    end

    -- Find the equipped weapon in inventory that matches current weapon hash
    for _, item in pairs(inventory) do
        if item.type == 'weapon' and GetHashKey(item.name) == weaponHash then
            if Config.Debug then
                print('Found matching weapon:')
                print('Name:', item.name)
                print('Label:', item.label)
                print('Serie:', item.info and item.info.serie or 'No serie')
            end
            
            if item.info and item.info.serie then
                return {
                    name = item.name,
                    label = item.label,
                    serial = item.info.serie
                }
            end
        end
    end
    
    return nil
end

-- Main MDT Command
RegisterCommand(Config.Command, function()
    local PlayerData = RSGCore.Functions.GetPlayerData()
    if Config.AllowedJobs[PlayerData.job.name] then
        OpenMainMenu()
    else
        lib.notify({ title = Config.Locales.error, description = Config.Locales.no_permission, type = 'error' })
    end
end)

-- Check Fines Command
RegisterCommand(Config.CheckFine, function()
    TriggerServerEvent('pure-mdt:server:getPersonalFines')
end)

-- Main Menu Function
function OpenMainMenu()
    lib.registerContext({
        id = 'mdt_main_menu',
        title = Config.Locales.mdt_title,
        options = {
            {
                title = Config.Locales.create_fine,
                description = Config.Locales.fine_desc,
                icon = 'file-invoice-dollar',
                onSelect = function()
                    TriggerEvent('pure-mdt:client:createFine')
                end
            },
            {
                title = Config.Locales.search_fines,
                description = Config.Locales.search_name,
                icon = 'magnifying-glass',
                onSelect = function()
                    TriggerEvent('pure-mdt:client:searchFines')
                end
            },
            {
                title = Config.Locales.register_weapon,
                description = Config.Locales.weapon_registration,
                icon = 'gun',
                onSelect = function()
                    TriggerEvent('pure-mdt:client:registerWeapon')
                end
            },
            {
                title = Config.Locales.search_weapons,
                description = Config.Locales.search_weapons,
                icon = 'search',
                onSelect = function()
                    TriggerEvent('pure-mdt:client:searchWeapons')
                end
            }
        }
    })
    lib.showContext('mdt_main_menu')
end

-- Create Fine Event
RegisterNetEvent('pure-mdt:client:createFine', function()
    local input = lib.inputDialog(Config.Locales.search_citizen, {
        { type = 'input', label = Config.Locales.search_name, required = true }
    })

    if input then
        TriggerServerEvent('pure-mdt:server:searchCitizens', input[1])
    end
end)

-- Show Citizen Results for Fine Creation
RegisterNetEvent('pure-mdt:client:showCitizenResults', function(results)
    local options = {}

    if results and #results > 0 then
        for _, v in pairs(results) do
            table.insert(options, {
                title = string.format('%s %s', v.firstname, v.lastname),
                description = string.format('CitizenID: %s', v.citizenid),
                icon = 'user',
                onSelect = function()
                    TriggerEvent('pure-mdt:client:createFineForCitizen', v)
                end
            })
        end
    else
        table.insert(options, {
            title = Config.Locales.no_results,
            icon = 'circle-xmark',
            disabled = true
        })
    end

    table.insert(options, {
        title = Config.Locales.back,
        icon = 'arrow-left',
        onSelect = function()
            OpenMainMenu()
        end
    })

    lib.registerContext({
        id = 'mdt_citizen_results',
        title = Config.Locales.select_citizen,
        options = options
    })
    lib.showContext('mdt_citizen_results')
end)

-- Create Fine for Selected Citizen
RegisterNetEvent('pure-mdt:client:createFineForCitizen', function(citizenData)
    local input = lib.inputDialog(string.format(Config.Locales.create_fine .. ' - %s %s', citizenData.firstname, citizenData.lastname), {
        { type = 'input', label = Config.Locales.reason, required = true },
        { type = 'number', label = Config.Locales.amount, required = true, min = Config.MinFineAmount, max = Config.MaxFineAmount },
        { type = 'input', label = Config.Locales.confiscated_weapon, required = false },
        { type = 'input', label = Config.Locales.prison_time, required = false }
    })

    if input then
        TriggerServerEvent('pure-mdt:server:createFine', {
            targetId = citizenData.id,
            firstname = citizenData.firstname,
            lastname = citizenData.lastname,
            citizenid = citizenData.citizenid,
            reason = input[1],
            amount = tonumber(input[2]),
            confiscated_weapon = input[3],
            prison_time = input[4]
        })
    end
end)

-- Search Fines Event
RegisterNetEvent('pure-mdt:client:searchFines', function()
    local input = lib.inputDialog(Config.Locales.search_fines, {
        { type = 'input', label = Config.Locales.search_name, required = true }
    })

    if input then
        TriggerServerEvent('pure-mdt:server:searchFines', input[1])
    end
end)

-- Register Weapon Event
RegisterNetEvent('pure-mdt:client:registerWeapon', function()
    -- First check if has weapon in hands
    local weaponData = GetEquippedWeapon()
    
    if not weaponData then
        lib.notify({ title = Config.Locales.error, description = Config.Locales.no_weapon_equipped, type = 'error' })
        return
    end

    if not weaponData.serial then
        lib.notify({ title = Config.Locales.error, description = Config.Locales.no_serial_found, type = 'error' })
        return
    end

    -- Show search dialog for citizen
    local input = lib.inputDialog(Config.Locales.search_citizen, {
        { type = 'input', label = Config.Locales.search_name, required = true }
    })

    if input then
        TriggerServerEvent('pure-mdt:server:searchCitizensForWeapon', input[1], weaponData)
    end
end)

-- Show Citizen Results for Weapon Registration
RegisterNetEvent('pure-mdt:client:showCitizenResultsForWeapon', function(results, weaponData)
    local options = {}

    if results and #results > 0 then
        for _, v in pairs(results) do
            table.insert(options, {
                title = string.format('%s %s', v.firstname, v.lastname),
                description = string.format('CitizenID: %s', v.citizenid),
                icon = 'user',
                onSelect = function()
                    TriggerEvent('pure-mdt:client:confirmWeaponRegistration', {
                        citizen = v,
                        weapon = weaponData
                    })
                end
            })
        end
    else
        table.insert(options, {
            title = Config.Locales.no_results,
            icon = 'circle-xmark',
            disabled = true
        })
    end

    table.insert(options, {
        title = Config.Locales.back,
        icon = 'arrow-left',
        onSelect = function()
            OpenMainMenu()
        end
    })

    lib.registerContext({
        id = 'mdt_citizen_weapon_results',
        title = Config.Locales.select_weapon_owner,
        options = options
    })
    lib.showContext('mdt_citizen_weapon_results')
end)

-- Confirm Weapon Registration
RegisterNetEvent('pure-mdt:client:confirmWeaponRegistration', function(data)
    lib.registerContext({
        id = 'mdt_confirm_weapon',
        title = Config.Locales.confirm_registration,
        options = {
            {
                title = string.format('%s: %s %s', Config.Locales.owner, data.citizen.firstname, data.citizen.lastname),
                description = string.format('%s: %s | %s: %s', 
                    Config.Locales.weapon_name, data.weapon.label,
                    Config.Locales.serial_number, data.weapon.serial
                ),
                icon = 'gun',
                disabled = true
            },
            {
                title = Config.Locales.confirm,
                description = Config.Locales.confirm_desc,
                icon = 'check',
                onSelect = function()
                    TriggerEvent('pure-mdt:client:finalizeWeaponRegistration', data)
                end
            },
            {
                title = Config.Locales.cancel,
                icon = 'xmark',
                onSelect = function()
                    OpenMainMenu()
                end
            }
        }
    })
    lib.showContext('mdt_confirm_weapon')
end)

-- Finalize Weapon Registration
RegisterNetEvent('pure-mdt:client:finalizeWeaponRegistration', function(data)
    TriggerServerEvent('pure-mdt:server:registerWeapon', {
        owner = string.format('%s %s', data.citizen.firstname, data.citizen.lastname),
        weapon = data.weapon.label,
        serial = data.weapon.serial,
        citizenid = data.citizen.citizenid
    })
end)

-- Search Weapons Menu
RegisterNetEvent('pure-mdt:client:searchWeapons', function()
    lib.registerContext({
        id = 'mdt_search_weapons',
        title = Config.Locales.search_weapons,
        menu = 'mdt_main_menu',
        options = {
            {
                title = Config.Locales.search_current_weapon,
                description = Config.Locales.search_current_desc,
                icon = 'crosshairs',
                onSelect = function()
                    TriggerEvent('pure-mdt:client:searchCurrentWeapon')
                end
            },
            {
                title = Config.Locales.search_by_serial,
                description = Config.Locales.serial_number,
                icon = 'barcode',
                onSelect = function()
                    TriggerEvent('pure-mdt:client:searchWeaponBySerial')
                end
            },
            {
                title = Config.Locales.search_by_owner,
                description = Config.Locales.weapon_owner,
                icon = 'user',
                onSelect = function()
                    TriggerEvent('pure-mdt:client:searchWeaponByOwner')
                end
            }
        }
    })
    lib.showContext('mdt_search_weapons')
end)

-- Search Current Weapon
RegisterNetEvent('pure-mdt:client:searchCurrentWeapon', function()
    local weaponData = GetEquippedWeapon()
    
    if not weaponData then
        lib.notify({ title = Config.Locales.error, description = Config.Locales.no_weapon_equipped, type = 'error' })
        return
    end

    if not weaponData.serial then
        lib.notify({ title = Config.Locales.error, description = Config.Locales.no_serial_found, type = 'error' })
        return
    end

    TriggerServerEvent('pure-mdt:server:searchWeaponBySerial', weaponData.serial)
end)

-- Search Weapon by Serial
RegisterNetEvent('pure-mdt:client:searchWeaponBySerial', function()
    local input = lib.inputDialog(Config.Locales.search_by_serial, {
        { type = 'input', label = Config.Locales.serial_number, required = true }
    })

    if input then
        TriggerServerEvent('pure-mdt:server:searchWeaponBySerial', input[1])
    end
end)

-- Search Weapon by Owner
RegisterNetEvent('pure-mdt:client:searchWeaponByOwner', function()
    local input = lib.inputDialog(Config.Locales.search_by_owner, {
        { type = 'input', label = Config.Locales.weapon_owner, required = true }
    })

    if input then
        TriggerServerEvent('pure-mdt:server:searchWeaponByOwner', input[1])
    end
end)

-- Show Search Results (For both fines and weapons)
RegisterNetEvent('pure-mdt:client:showSearchResults', function(results, searchType)
    local options = {}

    if results and #results > 0 then
        for _, v in pairs(results) do
            if searchType == 'fines' then
                table.insert(options, {
                    title = string.format('%s %s - $%s', v.firstname or 'N/A', v.lastname or 'N/A', v.amount),
                    description = string.format('%s | %s: %s | %s: %s',
                        v.reason,
                        Config.Locales.status, v.status or 'unpaid',
                        Config.Locales.date_issued, FormatDate(v.date)
                    ),
                    icon = 'file-invoice-dollar',
                    onSelect = function()
                        TriggerEvent('pure-mdt:client:viewFineDetails', v)
                    end
                })
            else
                table.insert(options, {
                    title = v.weapon_name or 'Unknown Weapon',
                    description = string.format('%s: %s | %s: %s',
                        Config.Locales.weapon_owner, v.owner_name,
                        Config.Locales.serial_number, v.serial_number
                    ),
                    icon = 'gun',
                    onSelect = function()
                        TriggerEvent('pure-mdt:client:viewWeaponDetails', v)
                    end
                })
            end
        end
    else
        table.insert(options, {
            title = Config.Locales.no_results,
            icon = 'circle-xmark',
            disabled = true
        })
    end

    lib.registerContext({
        id = 'mdt_search_results',
        title = Config.Locales.search_results,
        menu = searchType == 'fines' and 'mdt_main_menu' or 'mdt_search_weapons',
        options = options
    })
    lib.showContext('mdt_search_results')
end)

-- Show Personal Fines
RegisterNetEvent('pure-mdt:client:showPersonalFines', function(fines)
    local options = {}

    if fines and #fines > 0 then
        for _, fine in pairs(fines) do
            table.insert(options, {
                title = string.format('$%s - %s', fine.amount, fine.reason),
                description = string.format('%s: %s | %s: %s',
                    Config.Locales.issued_by, fine.officername,
                    Config.Locales.date_issued, FormatDate(fine.date)
                ),
                icon = 'file-invoice-dollar',
                onSelect = function()
                    TriggerEvent('pure-mdt:client:fineOptions', fine)
                end
            })
        end
    else
        table.insert(options, {
            title = Config.Locales.no_unpaid_fines,
            icon = 'circle-check',
            disabled = true
        })
    end

    lib.registerContext({
        id = 'mdt_personal_fines',
        title = Config.Locales.your_fines,
        options = options
    })
    lib.showContext('mdt_personal_fines')
end)

-- Fine Options Menu
RegisterNetEvent('pure-mdt:client:fineOptions', function(fine)
    lib.registerContext({
        id = 'mdt_fine_options',
        title = string.format(Config.Locales.fine_details, fine.amount),
        menu = 'mdt_personal_fines',
        options = {
            {
                title = Config.Locales.pay_fine,
                description = string.format(Config.Locales.pay_fine_desc, fine.amount),
                icon = 'money-bill',
                onSelect = function()
                    TriggerEvent('pure-mdt:client:confirmPayFine', fine)
                end
            }
        }
    })
    lib.showContext('mdt_fine_options')
end)

RegisterNetEvent('pure-mdt:client:confirmPayFine', function(fine)
    local alert = lib.alertDialog({
        header = string.format(Config.Locales.confirm_payment, fine.amount),
        content = string.format(Config.Locales.pay_fine_desc, fine.amount),
        centered = true,
        cancel = true
    })

    if alert == 'confirm' then
        if Config.Debug then
            print('Processing fine payment:', fine.id, 'Amount:', fine.amount)
        end
        TriggerServerEvent('pure-mdt:server:payFine', fine.id, fine.amount)
    end
end)

-- New process payment event
RegisterNetEvent('pure-mdt:client:processFinePayment', function(fine)
    if Config.Debug then
        print('Processing fine payment:', fine.id, 'Amount:', fine.amount)
    end
    TriggerServerEvent('pure-mdt:server:payFine', fine.id, fine.amount)
end)

-- Pay Fine (Legacy - kept for compatibility)
RegisterNetEvent('pure-mdt:client:payFine', function(fine)
    local alert = lib.alertDialog({
        header = string.format(Config.Locales.confirm_payment, fine.amount),
        content = Config.Locales.type_confirm,
        centered = true,
        cancel = true
    })

    if alert == 'confirm' then
        if Config.Debug then
            print('Attempting to pay fine:', fine.id, 'Amount:', fine.amount)
        end
        TriggerServerEvent('pure-mdt:server:payFine', fine.id, fine.amount)
    end
end)

-- View Fine Details
RegisterNetEvent('pure-mdt:client:viewFineDetails', function(data)
    local options = {
        {
            title = 'CID: ' .. data.citizenid,
            icon = 'id-card',
            disabled = true
        },
        {
            title = Config.Locales.amount .. ': $' .. data.amount,
            icon = 'dollar-sign',
            disabled = true
        },
        {
            title = Config.Locales.status .. ': ' .. (data.status or 'unpaid'),
            icon = 'circle-info',
            disabled = true
        },
        {
            title = Config.Locales.reason .. ': ' .. data.reason,
            icon = 'file-lines',
            disabled = true
        },
        {
            title = Config.Locales.confiscated_weapon .. ': ' .. (data.confiscated_weapon or Config.Locales.none),
            icon = 'gun',
            disabled = true
        },
        {
            title = Config.Locales.prison_time .. ': ' .. (data.prison_time or Config.Locales.none),
            icon = 'lock',
            disabled = true
        },
        {
            title = Config.Locales.issued_by .. ': ' .. data.officername,
            icon = 'user-shield',
            disabled = true
        },
        {
            title = Config.Locales.date_issued .. ': ' .. FormatDate(data.date),
            icon = 'calendar',
            disabled = true
        }
    }

    -- Add delete option for authorized personnel
    if RSGCore.Functions.GetPlayerData().job.isboss then
        table.insert(options, {
            title = Config.Locales.delete_fine,
            description = Config.Locales.delete_fine_desc,
            icon = 'trash',
            onSelect = function()
                TriggerEvent('pure-mdt:client:deleteFine', data)
            end
        })
    end

    lib.registerContext({
        id = 'mdt_fine_details',
        title = string.format('%s %s', data.firstname, data.lastname),
        menu = 'mdt_search_results',
        options = options
    })
    lib.showContext('mdt_fine_details')
end)

-- Delete Fine
RegisterNetEvent('pure-mdt:client:deleteFine', function(data)
    local alert = lib.alertDialog({
        header = Config.Locales.confirm_delete,
        content = Config.Locales.confirm_delete_desc,
        centered = true,
        cancel = true
    })

    if alert == 'confirm' then
        TriggerServerEvent('pure-mdt:server:deleteFine', data.id)
    end
end)

-- View Weapon Details
RegisterNetEvent('pure-mdt:client:viewWeaponDetails', function(data)
    local options = {
        {
            title = Config.Locales.weapon_owner .. ': ' .. data.owner_name,
            icon = 'user',
            disabled = true
        },
        {
            title = 'CID: ' .. data.citizenid,
            icon = 'id-card',
            disabled = true
        },
        {
            title = Config.Locales.serial_number .. ': ' .. data.serial_number,
            icon = 'barcode',
            disabled = true
        },
        {
            title = Config.Locales.registered_by .. ': ' .. data.registered_by,
            icon = 'user-shield',
            disabled = true
        },
        {
            title = Config.Locales.registration_date .. ': ' .. FormatDate(data.date),
            icon = 'calendar',
            disabled = true
        }
    }

    -- Add delete option for authorized personnel
    if RSGCore.Functions.GetPlayerData().job.isboss then
        table.insert(options, {
            title = Config.Locales.delete_registration,
            description = Config.Locales.delete_registration_desc,
            icon = 'trash',
            onSelect = function()
                TriggerEvent('pure-mdt:client:deleteWeaponRegistration', data)
            end
        })
    end

    lib.registerContext({
        id = 'mdt_weapon_details',
        title = data.weapon_name,
        menu = 'mdt_search_results',
        options = options
    })
    lib.showContext('mdt_weapon_details')
end)

-- Delete Weapon Registration
RegisterNetEvent('pure-mdt:client:deleteWeaponRegistration', function(data)
    local alert = lib.alertDialog({
        header = Config.Locales.confirm_delete,
        content = Config.Locales.confirm_delete_desc,
        centered = true,
        cancel = true
    })

    if alert == 'confirm' then
        TriggerServerEvent('pure-mdt:server:deleteWeaponRegistration', data.serial_number)
    end
end)

-- Return to Main Menu
RegisterNetEvent('pure-mdt:client:openMainMenu', function()
    OpenMainMenu()
end)