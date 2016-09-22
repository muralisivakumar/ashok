package com.example.administrator.databaseregistrationapp;


	import java.util.List;

	import android.app.Activity;
import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.TextView;

	public class StringAdapter extends ArrayAdapter<Bean>
	{
		List<Bean> StaffBeanItems ;
		 Context context;
		 public StringAdapter(List<Bean> resource,Context context) 
		 {
				 super(context,R.layout.items,resource);
				 // TODO Auto-generated constructor stub
				 this.context = context;
				 this.StaffBeanItems = resource;
		 }
		 public int getCount() 
		 {
				return StaffBeanItems.size();
		 }

		public Bean getItem(int position) 
		{
				return StaffBeanItems.get(position);
		}

		public long getItemId(int position) 
		{
				return StaffBeanItems.get(position).hashCode();
		}
		 @Override
		 public View getView(int position, View convertView, ViewGroup parent) 
		 {
				 // TODO Auto-generated method stub
				 LayoutInflater inflater = ((Activity)context).getLayoutInflater();
				 convertView = inflater.inflate(R.layout.items, parent, false); 
				 TextView name = (TextView) convertView.findViewById(R.id.itemstextView1);
				 
				 name.setText(StaffBeanItems.get(position).getName());
				 
				 return convertView;
		 }
}
