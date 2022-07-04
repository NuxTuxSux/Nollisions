using Plots, CSV


WIDTH, HEIGHT = 3072/2, 1920/2
BACKGROUND = colorant"black"
const τ = 2π
const PALETTE = collect(palette(:thermal))[1:170]

## params
const N = 6
# const vmax = 30
const vmax = 18

# Center of attraction
const Ω = WIDTH + HEIGHT*im
# const center = Circle(Ω.re,Ω.im,10)

# elastic constant
# const k = 0.0007
const k = 0.0007

acceleration(p::Complex, q::Complex; k::Float64 = k) = k*(q-p)


##
mutable struct Ball
    fig::Circle
    r::Number
    pos::Complex
    v::Complex
    color::RGB
    hit::Bool
    Ball(pos::Complex, r::Number, v::Complex = rand(1:vmax)exp(im*rand()τ); color::RGB = colorant"green") = new(Circle(convert(Int,round(pos.re)),convert(Int,round(pos.im)),r), r, pos, v, color, false)
end

function update!(b::Ball)
    p = b.pos - b.r*(1+im)
    b.fig.x, b.fig.y = convert(Int,round(p.re)), convert(Int,round(p.im))
end
function step!(b::Ball)
    b.pos += b.v
    b.v += acceleration(b.pos, Ω)
    update!(b)
end
function initState()
    pos = rand(90:130)*exp(im*rand()τ)
    vel = im*pos/abs(pos)*exp(im*(rand(-.4:.001:.4))*τ)*vmax
    pos + WIDTH + im*HEIGHT, vel
end
# colorsetter!(b::Ball, c::RGB) = function ()
    # b.color = c
# end
sethit!(b::Ball, hit::Bool) = function ()
    b.hit = hit
end

function updateCollision!(ball1::Ball, ball2::Ball)
    v = ball2.pos - ball1.pos
    axis = v/abs(v)
    R = (ball1.r + ball2.r)/6
    ball1.pos -= R*axis
    ball2.pos += R*axis
    update!(ball1)
    update!(ball2)
end

function draw(_::Game)
    [draw(ball.fig, ball.hit ? colorant"orange" : ball.color, fill = true) for ball in balls]
    # draw(center,colorant"red",fill=true)
end


function update(_::Game)
    global t₀, Δt
    t₁ = time()
    Δt = t₁-t₀
    t₀ = t₁
    for (i, ball) in enumerate(balls)
        step!(ball)
        for j in i+1:length(balls)
            otherBall = balls[j]
            if collide(ball.fig, otherBall.fig) && (ball != otherBall)
                # colorsetter!(ball, colorant"orange")()
                sethit!(ball, true)()
                sethit!(otherBall, true)()
                schedule_once(sethit!(ball, false), .1)
                schedule_once(sethit!(otherBall, false), .1)
                updateCollision!(ball,otherBall)
            end
        end
    end
end

t₀ = time()


balls = Ball[]
for _ in 1:N
    p, v = initState()
    push!(balls, Ball(p, rand(30:80), v, color = rand(PALETTE)))
end

function on_key_down(g::Game, key)
    # I don't like this design
    global balls, Δt
    if key == Keys.H
        for b in balls
            sethit!(b,false)()
        end
    elseif key == Keys.S
        CSV.write("snapshot.csv",(
            x = [ball.pos.re for ball in balls],
            y = [ball.pos.im for ball in balls],
            vx = [ball.v.re for ball in balls],
            vy = [ball.v.im for ball in balls],
            r = [ball.r for ball in balls],
            R = [red(ball.color) for ball in balls],
            G = [green(ball.color) for ball in balls],
            B = [blue(ball.color) for ball in balls]
        ))
    elseif key == Keys.F
        println(Δt)
    end
end