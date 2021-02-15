local function findSlot()
    for i = 1, 16 do
        if turtle.getItemSpace(i) > 0 then
            turtle.select(i)
            return
        end
    end
end
 
while true do
    local isBlock, data = turtle.inspect()
    if isBlock then
        if data.state and data.state.age == 7 then
            findSlot()
            turtle.dropUp()
            turtle.dig()
        end
    else
        turtle.place()
    end
    turtle.turnRight()
    sleep(30)
end
