extends RefCounted
class_name DeathMessages

#
const Messages : PackedStringArray = [
	# TMW dead messages
	"你已经倒下了。",
	"很遗憾，你的角色在战斗中阵亡了。",
	"你现在已经不太算活着了。",
	"游戏结束！",
	"投币即可继续。",
	"别担心，你的角色并没有真正消失。它……嗯，去了一个更好的地方。",
	"你的冒险价值已经用尽了。妈妈现在要你回家帮忙做晚饭。",
	"看来这次行动不太顺利。",
	"你已不复存在。",
	"你的生命已经走到了尽头。",
	"你已寿终正寝，去见造物主了。",
	"你已经变成一具尸体了。",
	"生命已逝，愿你安息。",
	"要不是你刚才还活蹦乱跳，现在坟头都该开花了。",
	"你已经离开人世了。",
	"你已经见阎王去了。",
	"你已经成为一名前玩家了。",
	"此刻，你一定很想立刻复活。",
	"等等，我刚才是不是死了？",
	"刚才到底发生了什么？",
	"看来你并不是那个天选之人。",
	"冥界再见。",
	"再试一次。",
	"别慌，你只是稍微死了一下。",
	"现在才开始挖坟，是不是有点晚了？",
	"程序已终止。",
	"任务失败。",
	"需要鉴定你的遗物吗？", # NetHack reference.
	"遗憾的是，再也没有人找到你的踪迹……", # Secret of Mana reference.
	"已被彻底消灭。", # Final Fantasy VI reference.
	"死亡很容易，活下去才更难。", # Final Fantasy XIV: Stormblood reference.
	"看来你这次输得很彻底。", # Earthbound reference.
	"你又搞砸了。把这具身体处理掉，再换一具新的吧。", # Leisure Suit Larry 1 reference.
	"你还没死，只是在休息而已。", # Monty Python reference.
	"每个人都有第一次跌倒的时候。", # The Matrix reference.
	"欢迎……来到真实的世界。", # The Matrix reference.
	"命运似乎总是带着一丝讽刺。", # The Matrix reference.
	"根本没有勺子。", # The Matrix reference.
	"一枪毙命。", # Call of Duty reference.
	"有些人只想看着世界燃烧。", # The Dark Knight reference.
	"你正在完成自己的宿命。", # Star Wars, Darth Sidious reference.
	"第八条规则：不要死。",
	"这里没有秩序，只有混乱。", # Pi reference.
	"真遗憾，振作起来吧。",
	"这里没有希望，只有死亡。", # The Fountain reference.
	"死亡是通往敬畏之境的道路。", # The Fountain reference.
	"停下……快停下！", # The Fountain reference.
	"今天是个适合战死的好日子。", # Klingons.
	"还有什么遗言吗？哎呀，太迟了！", 
	"混乱将成为我的墓志铭。", # King Crimson reference.
	"苦难本身并无荣耀。",
]

#
static func Pick() -> String:
	return Messages[randi() % Messages.size()]
