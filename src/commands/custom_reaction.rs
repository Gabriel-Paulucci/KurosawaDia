use std::time::Duration;

use serenity::{builder::CreateEmbed, client::Context, framework::standard::{Args, CommandResult, macros::{command, group}}, model::{channel::{Message, ReactionType}, guild::Guild}};

use crate::{database::{functions::custom_reaction::{add_custom_reaction, list_custom_reaction, remove_custom_reaction}, models::custom_reaction::DbCustomReactionType}, utils::constants::colors};

#[group]
#[commands(acr, aecr, dcr, lcr)]
pub struct CustomReaction;

#[command("adicionarrc")]
#[aliases("acr", "adicionarcr", "arc")]
#[only_in("guilds")]
#[min_args(3)]
async fn acr(ctx: &Context, msg: &Message, args: Args) -> CommandResult {
    let args = args.remains().unwrap().split('|').collect::<Vec<&str>>();

    if args.len() != 2 {
        return Ok(());
    }

    let guild = msg.guild(ctx).await.unwrap();

    create_custom_reaction(
        guild, 
        args[0].trim_end().to_string(), 
        args[1].trim_start().to_string(), 
        DbCustomReactionType::Normal
    ).await?;

    let mut embed = CreateEmbed::default();
    embed.title("Reação customizada adicionada com sucesso 😃");
    embed.color(colors::ORANGE);

    msg.channel_id.send_message(ctx, |x| x
        .set_embed(embed)
        .reference_message(msg)
    ).await?;

    Ok(())
}

#[command("adicionarrcespecial")]
#[aliases("aecr", "arce", "adicionarcrespecial")]
#[only_in("guilds")]
#[min_args(3)]
async fn aecr(ctx: &Context, msg: &Message, args: Args) -> CommandResult {
    let args = args.remains().unwrap().split('|').collect::<Vec<&str>>();

    if args.len() != 2 {
        return Ok(());
    }

    let guild = msg.guild(ctx).await.unwrap();

    create_custom_reaction(
        guild, 
        args[0].trim_end().to_string(), 
        args[1].trim_start().to_string(), 
        DbCustomReactionType::Especial
    ).await?;

    

    let mut embed = CreateEmbed::default();
    embed.title("Reação customizada especial adicionada com sucesso 😃");
    embed.color(colors::ORANGE);

    msg.channel_id.send_message(ctx, |x| x
        .set_embed(embed)
        .reference_message(msg)
    ).await?;

    Ok(())
}

async fn create_custom_reaction(guild: Guild, question: String, reply: String, cr_type: DbCustomReactionType) -> CommandResult {
    add_custom_reaction(guild, question, reply, cr_type).await?;

    Ok(())
}

#[command("deletecr")]
#[aliases("dcr")]
#[only_in("guilds")]
#[min_args(1)]
#[max_args(1)]
async fn dcr(ctx: &Context, msg: &Message, mut args: Args) -> CommandResult {
    let id = args.single::<u32>()?;

    let guild = msg.guild(ctx).await.unwrap();

    if remove_custom_reaction(guild, id).await? {
        let mut embed = CreateEmbed::default();
        embed.title("Reação customizada removida com sucesso 😊");
        embed.color(colors::ORANGE);

        msg.channel_id.send_message(ctx, |x| x
            .set_embed(embed)
            .reference_message(msg)
        ).await?;
    } else {
        let mut embed = CreateEmbed::default();
        embed.title("Reação customizada não encontrada 😔");
        embed.color(colors::YELLOW);

        msg.channel_id.send_message(ctx, |x| x
            .set_embed(embed)
            .reference_message(msg)
        ).await?;
    }

    Ok(())
}

#[command("listrc")]
#[aliases("lcr", "listarrc", "listcr")]
#[only_in("guilds")]
async fn lcr(ctx: &Context, msg: &Message, args: Args) -> CommandResult {
    let find = args.remains().unwrap_or("");

    let guild = msg.guild(ctx).await.unwrap();
    let mut page = 0;

    let mut message_send = false;
    let mut message: Option<Message> = None;

    loop {
        let custom_reactions = list_custom_reaction(&guild, find, page).await?;

        if !message_send {
            message = Some(msg.channel_id.send_message(ctx, |x| x
                .reference_message(msg)
                .reactions(vec![
                    ReactionType::Unicode("▶".into())
                ])
                .embed(|e| e
                    .title("Lista de reações customizadas")
                    .field(
                        format!("Página {}", page + 1), 
                        format!("```md\n{}\n```", custom_reactions.iter().fold("".to_string(), |result, cr| {
                            format!("{}\n{}", result, cr.format())
                        })), 
                        false
                    )
                    .color(colors::ORANGE)
                )
            ).await?);

            message_send = true;
        } else {
            message.clone().unwrap().edit(ctx, |x| x
                .embed(|e| e
                    .title("Lista de reações customizadas")
                    .field(
                        format!("Página {}", page + 1), 
                        format!("```md\n{}\n```", custom_reactions.iter().fold("".to_string(), |result, cr| {
                            format!("{}\n{}", result, cr.format())
                        })), 
                        false
                    )
                    .color(colors::ORANGE)
                )
            ).await?;
        }

        let collector = message.as_ref().unwrap().await_reaction(ctx)
            .timeout(Duration::from_secs(30))
            .author_id(msg.author.id)
            .await;

        match collector {
            Some(reaction) => {
                if reaction.is_added() {
                    let reaction = reaction.as_inner_ref();
            
                    if reaction.emoji.as_data() == "▶" {
                        page += 1;
                    }
                }
            },
            None => {
                break;
            }
        }
    }

    Ok(())
}