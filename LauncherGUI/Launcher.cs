﻿using Bot;
using Bot.Modelos;
using Discord.WebSocket;
using System;
using System.IO;
using System.Threading;
using System.Windows.Forms;
using System.ComponentModel;
using Bot.Singletons;

namespace LauncherGUI
{
    public partial class launcherGUI : Form
    {
        private const string nomeArquivo = "dblocal.ayura";
        public launcherGUI()
        {
            InitializeComponent();
        }

        private void LauncherGUI_Load(object sender, EventArgs e)
        {
            if(File.Exists(nomeArquivo))
            {
                txtLocal.Text = File.ReadAllText(nomeArquivo);
            }
        }

        private void BtLocal_Click(object sender, EventArgs e)
        {
            fdDBFinder.ShowDialog();
        }

        private void fdDBFinder_FileOk(object sender, CancelEventArgs e)
        {
            if(!fdDBFinder.FileName.EndsWith(".db"))
            {
                MessageBox.Show("Essa não é um db válida");
            } else
            {
               txtLocal.Text = fdDBFinder.FileName;
               if (File.Exists(nomeArquivo))
               {
                   File.Delete(nomeArquivo);
               }
               File.Create(nomeArquivo).Close();
               File.WriteAllText(nomeArquivo, txtLocal.Text);
            }
        }

        private void BtIniciar_Click(object sender, EventArgs e)
        {
            SingletonConfig.localConfig = txtLocal.Text;
            try
            {
                new Thread(() => new Core().IniciarBot()).Start();
                btIniciar.Enabled = false;
                MessageBox.Show("O bot foi iniciado");
            } catch (Exception erro)
            {
                MessageBox.Show($"Não foi possivel iniciar o bot: {erro}");
            }
        }
    }
}
