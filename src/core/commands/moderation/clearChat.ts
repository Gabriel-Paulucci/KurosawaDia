import BotPermissionError from '@bot/errors/botPermissionError'
import ClientPermissionError from '@bot/errors/clientPermissionError'
import { CommandAlias, CommandInfo, CommandName } from '@bot/helpers/command'
import { Command } from '@bot/models/commands'
import { Context } from '@bot/models/context'
import { delay } from '@utils/delay'
import { DMChannel } from 'discord.js'

@CommandName('clearchat')
@CommandAlias('clear', 'prune')
@CommandInfo({
    description: 'clearchat',
    module: 'moderation'
})
export default class ClearChat extends Command {
    async validPermission (ctx: Context): Promise<boolean> {
        if (!ctx.memberClient?.permissionsIn(ctx.channel).has(['MANAGE_MESSAGES'])) {
            throw new BotPermissionError(['MANAGE_MESSAGES'], ctx.channel)
        }

        if (!ctx.memberAuthor?.permissionsIn(ctx.channel).has(['MANAGE_MESSAGES'])) {
            throw new ClientPermissionError(['MANAGE_MESSAGES'], ctx.channel)
        }

        return true
    }

    async execCommand (ctx: Context): Promise<void> {
        let remaining = Number(ctx.args[0] ?? 10)

        if (Number.isNaN(remaining)) {
            return
        }

        if (ctx.channel instanceof DMChannel) {
            return
        }

        let messageId = ctx.message.id

        do {
            const amout = remaining > 99 ? 99 : remaining

            let messages = await ctx.channel.messages.fetch({
                limit: amout,
                before: messageId
            })

            if (!messages) {
                break
            }

            messageId = messages.last()?.id as string
            messages = messages.filter(msg => !msg.pinned)

            remaining -= messages.size

            await ctx.channel.bulkDelete(messages)
            await delay(1000)
        } while (remaining > 0)
    }
}
