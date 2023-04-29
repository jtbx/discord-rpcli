# discord-rpcli

Control Discord rich presence statuses from the command-line

discord-rpcli is a program that allows you to control and manipulate
your Discord rich presence status with ease, from the command line.

To start, you will need the LLVM D compiler (ldc2), the desktop Discord
client, and optionally, a Discord developer application (without one,
Discord will show your presence as "Playing discord-rpcli").

# Installing

To compile and install, just use make:

```
$ make
# make install
```

# Usage

discord-rpcli accepts presence values in the form of options passed
through the command-line. One such option is the `-s` option, which
stands for state. This is the "state" of your presence, and is
displayed on your profile popout. In fact, every setting customizable
through options (except `-c`) shows on your profile popout. To change
the activity you are "playing", you must change the name of your
Discord Developer Application at https://discord.com/developers.

To show a simple state, you can use:

```sh
discord-rpcli -s "My state here"
```

This can be customized further, for example if you're playing the game nInvaders,
the command might look like this:

```sh
discord-rpcli -c $ninvaders_clientid -s "Playing Level 1" -d "Score: $score" -I ninvaders
```

Here's a quick explanation:

 * `-c` specifies the Client ID, that is, the Discord Developer Application used.
   This application has information tied to it, such as the application name and presence images.
   The application name is displayed on the user's status, as "Playing $app_name". Here we use
   `$ninvaders_clientid` as a placeholder for your application's Client ID.
 * `-s` is the state, discussed earlier.
 * `-d` is the details of the presence. Usually this is short, it just provides extra details, that's all.
 * `-I` is the large image key. In your Discord Developer Application, you can add Rich Presence images
   that you can then use in your presence. Each image you add has a name, or "image key" you can choose.
   Using -I, you can specify an image key to use for the large image portion of the presence. If the image
   key is not found in the application, nothing is shown. Here we use `ninvaders` as our image key.

That's about the basics. To learn more, read the manual pages installed through `make install`.
You can run `man discord-rpcli` to learn more about the available options, and `man discord-rpcli.conf`
to learn more about the configuration file, which you can use to set defaults for each option.