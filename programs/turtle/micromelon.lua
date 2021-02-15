local function findSlot()
    for i = 1,16 do
        if turtle.getItemSpace(i) > 0 then
            turtle.select(i)
            return
        end
    end
end

while true do
    if  turtle.detect() then 
        turtle.dig()
    else
        findSlot()
        turtle.dropUp()
        turtle.turnRight()
        sleep(30)
    end
end
