package com.example.administrator.databaseregistrationapp;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Button;

public class MainActivity extends Activity
{
 Button login,registration;
 
    @Override
    protected void onCreate(Bundle savedInstanceState) 
    {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        login=(Button)findViewById(R.id.login);
        registration=(Button)findViewById(R.id.Registration);
        registration.setOnClickListener(new OnClickListener() 
        {
			@Override
			public void onClick(View v) 
			{
				// TODO Auto-generated method stub
				Intent registrationpage=new Intent(MainActivity.this,RegistrationPage.class);
				startActivity(registrationpage);
			}
		});
        
        
        
        login.setOnClickListener(new OnClickListener() 
        {
			
			@Override
			public void onClick(View arg0) 
			{
				// TODO Auto-generated method stub
				Intent loginpage=new Intent(MainActivity.this,LoginWebPage.class);
				startActivity(loginpage);
			}
		});
       
    }
     }


