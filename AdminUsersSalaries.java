package com.example.administrator.databaseregistrationapp;



import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Button;

public class AdminUsersSalaries extends Activity 
{
   Button users,salaries,fragmentdetails;
	@Override
	protected void onCreate(Bundle savedInstanceState) 
	{
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_admin_users_salaries);
         users=(Button)findViewById(R.id.users);
         salaries=(Button)findViewById(R.id.salaries);
         fragmentdetails=(Button)findViewById(R.id.fragment);
         users.setOnClickListener(new OnClickListener() 
         {
			
			@Override
			public void onClick(View arg0) 
			{
				// TODO Auto-generated method stub
				Intent viewpage=new Intent(AdminUsersSalaries.this,ViewPage.class);
				startActivity(viewpage);
			}
		});
         
         salaries.setOnClickListener(new OnClickListener() 
         {
			
			@Override
			public void onClick(View v)
			{
				// TODO Auto-generated method stub
				Intent viewpage1=new Intent(AdminUsersSalaries.this,ViewPage1.class);
				startActivity(viewpage1);
				
			}
		
		});
         fragmentdetails.setOnClickListener(new OnClickListener() 
         {
			
			@Override
			public void onClick(View arg0)
			{
				// TODO Auto-generated method stub
				Intent viewpage2=new Intent(AdminUsersSalaries.this,FragmentDetails.class);
				startActivity(viewpage2);
			}
		});
		
	}

}
