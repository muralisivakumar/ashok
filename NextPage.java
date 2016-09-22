package com.example.amulya.listviewcheckboxapp;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Button;
import android.widget.ListView;

public class NextPage extends Activity 
{

	ListView listitems;
	
	
	Button back;
	@Override
	protected void onCreate(Bundle savedInstanceState) 
	{
		super.onCreate(savedInstanceState); 
		setContentView(R.layout.activity_next_page);
        
		listitems = (ListView)findViewById(R.id.list1);
		back = (Button)findViewById(R.id.button);
		
		back.setOnClickListener(new OnClickListener() 
		{
			
			@Override
			public void onClick(View arg0) 
			{
				// TODO Auto-generated method stub
				
				Intent backPage = new Intent(NextPage.this,MainActivity.class);
				startActivity(backPage);
				
			}
		});
		
	}

}
