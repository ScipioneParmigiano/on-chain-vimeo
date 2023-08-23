import * as React from 'react';
import AppBar from '@mui/material/AppBar';
import Box from '@mui/material/Box';
import Toolbar from '@mui/material/Toolbar';
import IconButton from '@mui/material/IconButton';
import Typography from '@mui/material/Typography';
import Menu from '@mui/material/Menu';
import MenuIcon from '@mui/icons-material/Menu';
import Container from '@mui/material/Container';
import Avatar from '@mui/material/Avatar';
import Button from '@mui/material/Button';
import Tooltip from '@mui/material/Tooltip';
import MenuItem from '@mui/material/MenuItem';
import AdbIcon from '@mui/icons-material/Adb';
import Logo from './assets/logo-img.png';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import CssBaseline from '@mui/material/CssBaseline';
import { useState, useEffect } from 'react'
import detectEthereumProvider from '@metamask/detect-provider'


const darkTheme = createTheme({
    palette: {
      mode: 'dark',
    },
  });

const pages = ['Demo', 'Creator', 'Fan'];
function Navbar() {
  const [anchorElNav, setAnchorElNav] = React.useState(null);
  const [wallet,setWallet]=React.useState("");  

   const [hasProvider, setHasProvider] = useState(false);

  const handleOpenNavMenu = (event) => {
    setAnchorElNav(event.currentTarget);
  };
  const isWalletSet=wallet.length>0 ? 1:0;
  useEffect(() => {
    const getProvider = async () => {
      const provider = await detectEthereumProvider({ silent: true })
      setHasProvider((provider)) // transform provider to true or false
    }
    getProvider()

  }, [])

  const handleCloseNavMenu = () => {
    setAnchorElNav(null);
  };


  const toggleHandleSignIn= async (e)=>{

    if(wallet.length){
        setWallet('');
        setHasProvider(false) // transform provider to true or false
    }
else{

    let accounts = await window.ethereum.request({  
    method: "eth_requestAccounts",
  })  
  const [selectedAddress] = await window.ethereum.request({
    method: 'eth_requestAccounts',
  });
  const networkId = await window.ethereum.request({
    method: 'net_version',
  });

  const chainId = await window.ethereum.request({
    method: 'eth_chainId',
  });


  console.log('Selected Address:', selectedAddress);
  console.log('Network ID:', networkId);
  console.log('Chain ID:', chainId);
  console.log('Accounts:', accounts);
  
setWallet(accounts[0]);
}

}

const truncateString= (inputString)=> {
    if (inputString.length <= 5) {
      return inputString;
    } else {
      return inputString.slice(0, 5) + "...";
    }
  }
 

  return (
    <ThemeProvider theme={darkTheme}>
    <AppBar position="static">
      <Container maxWidth="xl">
        <Toolbar disableGutters>
          <AdbIcon sx={{ display: { xs: 'none', md: 'flex' }, mr: 1 }} />
          <Typography
            variant="h6"
            noWrap
            component="a"
            href="/"
            sx={{
              mr: 2,
              display: { xs: 'none', md: 'flex' },
              fontFamily: 'monospace',
              fontWeight: 700,
              letterSpacing: '.3rem',
              color: 'inherit',
              textDecoration: 'none',
            }}
          >
          StarConnect
          </Typography>

          <Box sx={{ flexGrow: 1, display: { xs: 'flex', md: 'none' } }}>
            <IconButton
              size="large"
              aria-label="account of current user"
              aria-controls="menu-appbar"
              aria-haspopup="true"
              onClick={handleOpenNavMenu}
              color="inherit"
            >
              <MenuIcon />
            </IconButton>
            <Menu
              id="menu-appbar"
              anchorEl={anchorElNav}
              anchorOrigin={{
                vertical: 'bottom',
                horizontal: 'left',
              }}
              keepMounted
              transformOrigin={{
                vertical: 'top',
                horizontal: 'left',
              }}
              open={Boolean(anchorElNav)}
              onClose={handleCloseNavMenu}
              sx={{
                display: { xs: 'block', md: 'none' },
              }}
            >
              {pages.map((page) => (
                <MenuItem key={page} onClick={handleCloseNavMenu}>
                  <Typography textAlign="center">{page}</Typography>
                </MenuItem>
              ))}
            </Menu>
          </Box>
          {/* <AdbIcon sx={{ display: { xs: 'flex', md: 'none' }, mr: 1 }} /> */}
          <Typography
            variant="h5"
            noWrap
            component="a"
            href="/"
            sx={{
              mr: 2,
              display: { xs: 'flex', md: 'none' },
              flexGrow: 1,
              fontFamily: 'monospace',
              fontWeight: 700,
              letterSpacing: '.3rem',
              color: 'inherit',
              textDecoration: 'none',
            }}
          >
             {/* <img src={Logo} alt='logo ' style={{width:150+"px",height: 100+"px"}} /> */}
             StarConnect
          </Typography>
          <Box sx={{ flexGrow: 1, display: { xs: 'none', md: 'flex' } }}>
            {pages.map((page) => (
              <Button
                key={page}
                onClick={handleCloseNavMenu}
                sx={{ my: 2, color: 'white', display: 'block' }}
              >
                {page}
              </Button>
            ))}
          </Box>
          
          <Button variant="inherit" onClick={toggleHandleSignIn}> { (isWalletSet)? `Sign Out \n ${truncateString(wallet)}`:`Sign In`}</Button>
        </Toolbar>
      </Container>
    </AppBar>
    </ThemeProvider>
  );
}
export default Navbar;