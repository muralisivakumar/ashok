package com.example.administrator.databaseregistrationapp;
import java.util.ArrayList;
import java.util.List;



import android.app.Activity;
import android.app.Fragment;
import android.app.FragmentManager;
import android.app.FragmentTransaction;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.view.Menu;
import android.view.View;
import android.widget.AdapterView;
import android.widget.ListView;

public class FragmentDetails extends Activity 
{
	Fragment fragment = null;
	ListView trustListView;
	FragmentManager fragmentManager;
	FragmentTransaction fragmentTransaction;
	ArrayList<String> deptNames = new ArrayList<String>();
	List<Bean> deptBeanItems = new ArrayList<Bean>();
	StringAdapter deptAdapter;
	@Override
	protected void onCreate(Bundle savedInstanceState) 
	{
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_fragment_details);
		trustListView = (ListView) findViewById(R.id.listView1);
		deptNames.add("Users");
		deptNames.add("Salaries");
		deptNames.add("Products");
		deptNames.add("Adresses");
		deptNames.add("ActivityInfo");
		deptNames.add("Gallery");

	
		for (int i = 0; i < deptNames.size(); i++) 
		{
			deptBeanItems.add(new Bean(deptNames.get(i)));
		}
		deptAdapter = new StringAdapter(deptBeanItems,this);
		trustListView.setAdapter(deptAdapter);
		trustListView.setOnItemClickListener(new AdapterView.OnItemClickListener() 
		{

			@Override
			public void onItemClick(AdapterView<?> parentAdapter, View view,int position, long id) 
			{
				// TODO Auto-generated method stub
				displayView(position);
			}
		});
	}
	private void displayView(int position) 
	{
		// update the main content by replacing fragments
		Fragment fragment = null;
		switch (position) 
		{
			case 0:
		 fragment=new Fragment0();
				//Intent viewpage1=new Intent(FragmentDetails.this,ViewPage.class);
				//startActivity(viewpage1);
				break;
			case 1:
				fragment = new Fragment1();
				break;
			case 2:
				fragment = new Fragment2();
				break;
			case 3:
				fragment = new Fragment3();
				break;
			case 4:
				fragment = new Fragment4();
			    break; 
			    
			case 5:
				fragment = new Fragment5();
			    break; 
			default:
				break;
		}

		if (fragment != null) 
		{
			
			/*FragmentManager fragmentManager = getFragmentManager();
			fragmentManager.beginTransaction()
					.replace(R.id.frame_container, fragment).commit();
			fragmentManager.popBackStack();*/
			
			FragmentManager fragmentManager = getFragmentManager();
			FragmentTransaction fragmentTransaction = fragmentManager.beginTransaction();
        	        fragmentTransaction.replace(R.id.displayFragment, fragment);
			fragmentTransaction.addToBackStack(null);
			fragmentTransaction.setTransition(FragmentTransaction.TRANSIT_FRAGMENT_OPEN);
			fragmentTransaction.commit();
			
			// update selected item and title, then close the drawer
			trustListView.setItemChecked(position, true);
			trustListView.setSelection(position);
		} else {
			Log.e("MainActivity", "Error in creating fragment");
		}
	}


}
